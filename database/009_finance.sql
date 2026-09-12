-- HEAVEN PLATAFORMA — FINANCEIRO INTEGRADO

do $$ begin
  create type public.financial_direction as enum ('receber','pagar');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.financial_status as enum ('pendente','parcial','pago','vencido','cancelado');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.financial_category as enum ('venda','sinal','saldo','caucao','logistica','compra','manutencao','reembolso','taxa','outro');
exception when duplicate_object then null; end $$;

create table if not exists public.financial_accounts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  account_type text not null default 'caixa' check(account_type in ('caixa','banco','carteira','outro')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(company_id,name)
);

create table if not exists public.financial_entries (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contract_id uuid references public.contracts(id) on delete set null,
  event_id uuid references public.events(id) on delete set null,
  client_id uuid references public.clients(id) on delete set null,
  logistics_run_id uuid references public.logistics_runs(id) on delete set null,
  direction public.financial_direction not null,
  category public.financial_category not null default 'outro',
  description text not null,
  amount numeric(12,2) not null check(amount >= 0),
  due_date date,
  status public.financial_status not null default 'pendente',
  is_security_deposit boolean not null default false,
  refundable boolean not null default false,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.financial_payments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  entry_id uuid not null references public.financial_entries(id) on delete cascade,
  account_id uuid references public.financial_accounts(id) on delete set null,
  amount numeric(12,2) not null check(amount > 0),
  paid_at timestamptz not null default now(),
  payment_method text,
  reference text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists financial_entries_company_due_idx on public.financial_entries(company_id,status,due_date);
create index if not exists financial_entries_contract_idx on public.financial_entries(company_id,contract_id);
create index if not exists financial_entries_event_idx on public.financial_entries(company_id,event_id);
create index if not exists financial_payments_entry_idx on public.financial_payments(entry_id,paid_at);

alter table public.financial_accounts enable row level security;
alter table public.financial_entries enable row level security;
alter table public.financial_payments enable row level security;
revoke all on public.financial_accounts,public.financial_entries,public.financial_payments from anon;
grant select,insert,update,delete on public.financial_accounts,public.financial_entries,public.financial_payments to authenticated;

do $$ declare t text; begin
 foreach t in array array['financial_accounts','financial_entries','financial_payments'] loop
  execute format('drop policy if exists %I on public.%I',t||'_select_member',t);
  execute format('create policy %I on public.%I for select to authenticated using (private.is_company_member(company_id))',t||'_select_member',t);
  execute format('drop policy if exists %I on public.%I',t||'_insert_member',t);
  execute format('create policy %I on public.%I for insert to authenticated with check (private.is_company_member(company_id))',t||'_insert_member',t);
  execute format('drop policy if exists %I on public.%I',t||'_update_member',t);
  execute format('create policy %I on public.%I for update to authenticated using (private.is_company_member(company_id)) with check (private.is_company_member(company_id))',t||'_update_member',t);
  execute format('drop policy if exists %I on public.%I',t||'_delete_management',t);
  execute format('create policy %I on public.%I for delete to authenticated using (private.has_company_role(company_id,array[''proprietario'',''administrador'',''gerente'']::public.company_role[]))',t||'_delete_management',t);
 end loop;
end $$;

-- Total pago e saldo por lançamento.
create or replace view public.financial_entry_balances with(security_invoker=true) as
select e.*,
 coalesce(sum(p.amount),0)::numeric(12,2) as paid_amount,
 greatest(e.amount-coalesce(sum(p.amount),0),0)::numeric(12,2) as open_amount
from public.financial_entries e
left join public.financial_payments p on p.entry_id=e.id and p.company_id=e.company_id
group by e.id;
grant select on public.financial_entry_balances to authenticated;

-- Registra pagamento/recebimento e recalcula status sem editar o valor original do título.
create or replace function public.register_financial_payment(target_entry_id uuid,payment_amount numeric,target_account_id uuid default null,target_method text default null,target_reference text default null)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare e public.financial_entries%rowtype; payment_id uuid; paid_total numeric;
begin
 if payment_amount<=0 then raise exception 'Valor inválido'; end if;
 select * into e from public.financial_entries where id=target_entry_id for update;
 if not found or not private.is_company_member(e.company_id) then raise exception 'Lançamento não encontrado'; end if;
 if e.status='cancelado' then raise exception 'Lançamento cancelado'; end if;
 if target_account_id is not null and not exists(select 1 from public.financial_accounts a where a.id=target_account_id and a.company_id=e.company_id) then raise exception 'Conta financeira inválida'; end if;
 select coalesce(sum(amount),0) into paid_total from public.financial_payments where entry_id=e.id;
 if paid_total+payment_amount>e.amount then raise exception 'Pagamento excede saldo do lançamento'; end if;
 insert into public.financial_payments(company_id,entry_id,account_id,amount,payment_method,reference,created_by)
 values(e.company_id,e.id,target_account_id,payment_amount,target_method,target_reference,auth.uid()) returning id into payment_id;
 paid_total:=paid_total+payment_amount;
 update public.financial_entries set status=case when paid_total>=amount then 'pago'::public.financial_status else 'parcial'::public.financial_status end,updated_at=now() where id=e.id;
 return payment_id;
end;
$$;
revoke all on function public.register_financial_payment(uuid,numeric,uuid,text,text) from public,anon;
grant execute on function public.register_financial_payment(uuid,numeric,uuid,text,text) to authenticated;

-- Gera recebíveis a partir do contrato. Percentuais/parcelas são parâmetros do tenant, não regra da Heaven.
create or replace function public.create_contract_receivables(target_contract_id uuid,deposit_amount numeric default 0,deposit_due date default current_date,balance_due date default null,security_deposit_amount numeric default 0)
returns integer
language plpgsql
security definer
set search_path=''
as $$
declare ct public.contracts%rowtype; total numeric; remaining numeric; affected integer:=0;
begin
 select * into ct from public.contracts where id=target_contract_id;
 if not found or not private.is_company_member(ct.company_id) then raise exception 'Contrato não encontrado'; end if;
 total:=coalesce((ct.commercial_snapshot->>'total')::numeric,0);
 if deposit_amount<0 or security_deposit_amount<0 or deposit_amount>total then raise exception 'Valores inválidos'; end if;
 remaining:=total-deposit_amount;
 if deposit_amount>0 and not exists(select 1 from public.financial_entries where contract_id=ct.id and category='sinal' and status<>'cancelado') then
  insert into public.financial_entries(company_id,contract_id,client_id,direction,category,description,amount,due_date,created_by)
  values(ct.company_id,ct.id,ct.client_id,'receber','sinal','Sinal do contrato',deposit_amount,deposit_due,auth.uid()); affected:=affected+1;
 end if;
 if remaining>0 and not exists(select 1 from public.financial_entries where contract_id=ct.id and category='saldo' and status<>'cancelado') then
  insert into public.financial_entries(company_id,contract_id,client_id,direction,category,description,amount,due_date,created_by)
  values(ct.company_id,ct.id,ct.client_id,'receber','saldo','Saldo do contrato',remaining,balance_due,auth.uid()); affected:=affected+1;
 end if;
 if security_deposit_amount>0 and not exists(select 1 from public.financial_entries where contract_id=ct.id and is_security_deposit and status<>'cancelado') then
  insert into public.financial_entries(company_id,contract_id,client_id,direction,category,description,amount,due_date,is_security_deposit,refundable,created_by)
  values(ct.company_id,ct.id,ct.client_id,'receber','caucao','Caução',security_deposit_amount,deposit_due,true,true,auth.uid()); affected:=affected+1;
 end if;
 return affected;
end;
$$;
revoke all on function public.create_contract_receivables(uuid,numeric,date,date,numeric) from public,anon;
grant execute on function public.create_contract_receivables(uuid,numeric,date,date,numeric) to authenticated;

-- Caução recebida não é receita: devolução gera saída vinculada ao contrato.
create or replace function public.refund_security_deposit(target_entry_id uuid,target_account_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare e public.financial_entries%rowtype; received numeric; refund_entry uuid;
begin
 select * into e from public.financial_entries where id=target_entry_id;
 if not found or not private.is_company_member(e.company_id) or not e.is_security_deposit then raise exception 'Caução não encontrada'; end if;
 select coalesce(sum(amount),0) into received from public.financial_payments where entry_id=e.id;
 if received<=0 then raise exception 'Caução ainda não recebida'; end if;
 if exists(select 1 from public.financial_entries x where x.contract_id=e.contract_id and x.category='reembolso' and x.description='Devolução de caução' and x.status<>'cancelado') then raise exception 'Devolução já registrada'; end if;
 insert into public.financial_entries(company_id,contract_id,event_id,client_id,direction,category,description,amount,due_date,status,created_by)
 values(e.company_id,e.contract_id,e.event_id,e.client_id,'pagar','reembolso','Devolução de caução',received,current_date,'pendente',auth.uid()) returning id into refund_entry;
 return refund_entry;
end;
$$;
revoke all on function public.refund_security_deposit(uuid,uuid) from public,anon;
grant execute on function public.refund_security_deposit(uuid,uuid) to authenticated;

-- Caixa realizado usa pagamentos, não títulos em aberto. Caução entra separada da receita operacional.
create or replace view public.cash_movements with(security_invoker=true) as
select p.company_id,p.id as payment_id,p.entry_id,p.account_id,p.paid_at,p.amount,e.direction,e.category,e.description,e.contract_id,e.event_id,e.client_id,e.is_security_deposit,
 case when e.direction='receber' then p.amount else -p.amount end as signed_amount,
 case when e.is_security_deposit then 0 when e.direction='receber' then p.amount else -p.amount end as operating_amount
from public.financial_payments p join public.financial_entries e on e.id=p.entry_id and e.company_id=p.company_id;
grant select on public.cash_movements to authenticated;
