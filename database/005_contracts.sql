-- HEAVEN PLATAFORMA — CONTRATOS
-- Contrato nasce de orçamento aprovado e preserva snapshot da negociação.

do $$ begin
  create type public.contract_status as enum ('rascunho','aguardando_assinatura','ativo','concluido','cancelado');
exception when duplicate_object then null; end $$;

create table if not exists public.contracts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  quote_id uuid not null references public.quotes(id) on delete restrict,
  client_id uuid not null references public.clients(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  status public.contract_status not null default 'rascunho',
  contract_number text,
  customer_snapshot jsonb not null,
  event_snapshot jsonb not null,
  commercial_snapshot jsonb not null,
  items_snapshot jsonb not null default '[]'::jsonb,
  terms_snapshot jsonb not null default '{}'::jsonb,
  signed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, quote_id)
);

create index if not exists contracts_company_status_idx on public.contracts(company_id, status);
create index if not exists contracts_client_idx on public.contracts(company_id, client_id);

alter table public.contracts enable row level security;
revoke all on public.contracts from anon;
grant select, insert, update on public.contracts to authenticated;
grant delete on public.contracts to authenticated;

drop policy if exists contracts_select_member on public.contracts;
create policy contracts_select_member on public.contracts for select to authenticated using (private.is_company_member(company_id));
drop policy if exists contracts_insert_member on public.contracts;
create policy contracts_insert_member on public.contracts for insert to authenticated with check (private.is_company_member(company_id));
drop policy if exists contracts_update_member on public.contracts;
create policy contracts_update_member on public.contracts for update to authenticated using (private.is_company_member(company_id)) with check (private.is_company_member(company_id));
drop policy if exists contracts_delete_admin on public.contracts;
create policy contracts_delete_admin on public.contracts for delete to authenticated using (private.has_company_role(company_id, array['proprietario','administrador']::public.company_role[]));

create or replace function public.create_contract_from_quote(target_quote_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  q public.quotes%rowtype;
  c public.clients%rowtype;
  new_contract_id uuid;
  item_snapshot jsonb;
begin
  select * into q from public.quotes where id = target_quote_id;
  if not found or not private.is_company_member(q.company_id) then raise exception 'Orçamento não encontrado'; end if;
  if q.status <> 'aprovado' then raise exception 'Somente orçamento aprovado pode gerar contrato'; end if;
  if q.client_id is null then raise exception 'Orçamento aprovado precisa estar vinculado a um cliente'; end if;

  select * into c from public.clients where id = q.client_id and company_id = q.company_id;
  if not found then raise exception 'Cliente não encontrado'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'type', qi.item_type, 'description', qi.description, 'quantity', qi.quantity,
    'unit_price', qi.unit_price, 'total', qi.total, 'display_order', qi.display_order
  ) order by qi.display_order), '[]'::jsonb)
  into item_snapshot from public.quote_items qi where qi.quote_id = q.id and qi.company_id = q.company_id;

  insert into public.contracts(
    company_id, quote_id, client_id, created_by,
    customer_snapshot, event_snapshot, commercial_snapshot, items_snapshot
  ) values (
    q.company_id, q.id, c.id, auth.uid(),
    jsonb_build_object('name',c.name,'phone',c.phone,'email',c.email,'document',c.document,'address',c.address,'city',c.city,'state',c.state),
    jsonb_build_object('type',q.event_type,'date',q.event_date,'address',q.event_address,'city',q.event_city,'state',q.event_state),
    jsonb_build_object('title',q.title,'subtotal',q.subtotal,'discount',q.discount,'total',q.total,'valid_until',q.valid_until,'customer_notes',q.customer_notes),
    item_snapshot
  )
  on conflict (company_id, quote_id) do update set updated_at = now()
  returning id into new_contract_id;

  return new_contract_id;
end;
$$;

revoke all on function public.create_contract_from_quote(uuid) from public, anon;
grant execute on function public.create_contract_from_quote(uuid) to authenticated;
