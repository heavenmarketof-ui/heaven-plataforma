-- HEAVEN PLATAFORMA — PRODUÇÃO / SEPARAÇÃO + LOGÍSTICA

do $$ begin
  create type public.production_status as enum ('aguardando','em_separacao','pronto','liberado','concluido','cancelado');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.logistics_status as enum ('planejado','confirmado','em_rota','no_local','concluido','cancelado');
exception when duplicate_object then null; end $$;

create table if not exists public.production_orders (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  responsible_user_id uuid references auth.users(id) on delete set null,
  status public.production_status not null default 'aguardando',
  separation_due_at timestamptz,
  ready_at timestamptz,
  released_at timestamptz,
  completed_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id,event_id)
);

create table if not exists public.logistics_runs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  operation_id uuid references public.event_operations(id) on delete set null,
  operation_type public.operation_type not null,
  responsible_user_id uuid references auth.users(id) on delete set null,
  status public.logistics_status not null default 'planejado',
  scheduled_at timestamptz,
  scheduled_end_at timestamptz,
  address text,
  contact_name text,
  contact_phone text,
  external_provider text,
  external_reference text,
  cost numeric(12,2),
  notes text,
  started_at timestamptz,
  arrived_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id,operation_id)
);

create index if not exists production_orders_status_idx on public.production_orders(company_id,status,separation_due_at);
create index if not exists logistics_runs_schedule_idx on public.logistics_runs(company_id,status,scheduled_at);

alter table public.production_orders enable row level security;
alter table public.logistics_runs enable row level security;
revoke all on public.production_orders,public.logistics_runs from anon;
grant select,insert,update,delete on public.production_orders,public.logistics_runs to authenticated;

do $$ declare t text; begin
  foreach t in array array['production_orders','logistics_runs'] loop
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

-- Cria/atualiza a ordem de separação a partir do evento e gera checklist de saída.
create or replace function public.prepare_event_for_production(target_event_id uuid, due_at timestamptz default null)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare ev public.events%rowtype; order_id uuid;
begin
  select * into ev from public.events where id=target_event_id;
  if not found or not private.is_company_member(ev.company_id) then raise exception 'Evento não encontrado'; end if;
  if ev.status in ('concluido','cancelado') then raise exception 'Evento encerrado'; end if;

  perform public.prepare_event_inventory_check(ev.id,'separacao');
  insert into public.production_orders(company_id,event_id,separation_due_at)
  values(ev.company_id,ev.id,coalesce(due_at,ev.starts_at - interval '1 day'))
  on conflict(company_id,event_id) do update set separation_due_at=coalesce(excluded.separation_due_at,public.production_orders.separation_due_at),updated_at=now()
  returning id into order_id;
  update public.events set status='em_preparacao',updated_at=now() where id=ev.id and status in ('planejamento','confirmado');
  return order_id;
end;
$$;
revoke all on function public.prepare_event_for_production(uuid,timestamptz) from public,anon;
grant execute on function public.prepare_event_for_production(uuid,timestamptz) to authenticated;

-- Só permite marcar como pronto quando todos os itens de separação foram conferidos como OK.
create or replace function public.mark_production_ready(target_order_id uuid)
returns void
language plpgsql
security definer
set search_path=''
as $$
declare po public.production_orders%rowtype; pending_count integer;
begin
  select * into po from public.production_orders where id=target_order_id;
  if not found or not private.is_company_member(po.company_id) then raise exception 'Ordem não encontrada'; end if;
  select count(*) into pending_count from public.inventory_checks c
    where c.event_id=po.event_id and c.phase='separacao' and c.status <> 'ok';
  if pending_count > 0 then raise exception 'Separação possui % item(ns) pendente(s) ou divergente(s)',pending_count; end if;
  update public.production_orders set status='pronto',ready_at=now(),updated_at=now() where id=po.id;
  update public.inventory_reservations set status='separada',updated_at=now() where event_id=po.event_id and status='confirmada';
end;
$$;
revoke all on function public.mark_production_ready(uuid) from public,anon;
grant execute on function public.mark_production_ready(uuid) to authenticated;

-- Espelha operações logísticas do evento em um painel executável.
create or replace function public.sync_event_logistics(target_event_id uuid)
returns integer
language plpgsql
security definer
set search_path=''
as $$
declare ev public.events%rowtype; affected integer;
begin
  select * into ev from public.events where id=target_event_id;
  if not found or not private.is_company_member(ev.company_id) then raise exception 'Evento não encontrado'; end if;
  insert into public.logistics_runs(company_id,event_id,operation_id,operation_type,responsible_user_id,scheduled_at,scheduled_end_at,address,notes)
  select eo.company_id,eo.event_id,eo.id,eo.operation_type,eo.responsible_user_id,eo.scheduled_at,eo.scheduled_end_at,eo.address,eo.notes
  from public.event_operations eo
  where eo.event_id=ev.id and eo.operation_type in ('retirada','entrega','montagem','desmontagem','devolucao') and eo.status <> 'cancelada'
  on conflict(company_id,operation_id) do update set
    responsible_user_id=excluded.responsible_user_id,scheduled_at=excluded.scheduled_at,scheduled_end_at=excluded.scheduled_end_at,address=excluded.address,notes=excluded.notes,updated_at=now();
  get diagnostics affected=row_count;
  return affected;
end;
$$;
revoke all on function public.sync_event_logistics(uuid) from public,anon;
grant execute on function public.sync_event_logistics(uuid) to authenticated;

-- Encerramento operacional: exige devolução/conferência quando houver itens reservados.
create or replace function public.close_event_operation(target_event_id uuid)
returns void
language plpgsql
security definer
set search_path=''
as $$
declare ev public.events%rowtype; reservation_count integer; bad_returns integer; open_logistics integer;
begin
  select * into ev from public.events where id=target_event_id;
  if not found or not private.is_company_member(ev.company_id) then raise exception 'Evento não encontrado'; end if;
  select count(*) into open_logistics from public.logistics_runs where event_id=ev.id and status not in ('concluido','cancelado');
  if open_logistics>0 then raise exception 'Existem % operação(ões) logística(s) pendente(s)',open_logistics; end if;

  select count(*) into reservation_count from public.inventory_reservations where event_id=ev.id and status <> 'cancelada';
  if reservation_count>0 then
    perform public.prepare_event_inventory_check(ev.id,'devolucao');
    select count(*) into bad_returns from public.inventory_checks where event_id=ev.id and phase='devolucao' and status <> 'ok';
    if bad_returns>0 then raise exception 'Devolução possui % item(ns) pendente(s) ou divergente(s)',bad_returns; end if;
    update public.inventory_reservations set status='devolvida',updated_at=now() where event_id=ev.id and status <> 'cancelada';
  end if;

  update public.production_orders set status='concluido',completed_at=coalesce(completed_at,now()),updated_at=now() where event_id=ev.id and status <> 'cancelado';
  update public.events set status='concluido',updated_at=now() where id=ev.id;
end;
$$;
revoke all on function public.close_event_operation(uuid) from public,anon;
grant execute on function public.close_event_operation(uuid) to authenticated;

create or replace view public.production_board with(security_invoker=true) as
select po.company_id,po.id as production_order_id,po.event_id,po.status,po.separation_due_at,po.responsible_user_id,
 e.title,e.starts_at,e.city,
 count(c.id) as checklist_total,
 count(c.id) filter(where c.status='ok') as checklist_ok,
 count(c.id) filter(where c.status not in ('ok')) as checklist_pending
from public.production_orders po join public.events e on e.id=po.event_id and e.company_id=po.company_id
left join public.inventory_checks c on c.event_id=po.event_id and c.phase='separacao'
group by po.company_id,po.id,po.event_id,po.status,po.separation_due_at,po.responsible_user_id,e.title,e.starts_at,e.city;
grant select on public.production_board to authenticated;
