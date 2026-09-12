-- HEAVEN PLATAFORMA — ESTOQUE, RESERVAS, SEPARAÇÃO E DEVOLUÇÃO

do $$ begin
  create type public.inventory_item_status as enum ('ativo','manutencao','inativo');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.reservation_status as enum ('provisoria','confirmada','separada','em_uso','devolvida','cancelada');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.check_item_status as enum ('pendente','ok','faltando','avariado','perdido');
exception when duplicate_object then null; end $$;

create table if not exists public.inventory_categories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(company_id, name)
);

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  category_id uuid references public.inventory_categories(id) on delete set null,
  sku text,
  name text not null,
  description text,
  total_quantity numeric(12,3) not null default 1 check(total_quantity >= 0),
  track_quantity boolean not null default true,
  status public.inventory_item_status not null default 'ativo',
  replacement_cost numeric(12,2),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, sku)
);

create table if not exists public.inventory_reservations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity numeric(12,3) not null check(quantity > 0),
  reserved_from timestamptz not null,
  reserved_until timestamptz not null,
  status public.reservation_status not null default 'provisoria',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check(reserved_until > reserved_from),
  unique(event_id, item_id)
);

create table if not exists public.inventory_checks (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  reservation_id uuid not null references public.inventory_reservations(id) on delete cascade,
  phase text not null check(phase in ('separacao','devolucao')),
  expected_quantity numeric(12,3) not null,
  checked_quantity numeric(12,3) not null default 0,
  status public.check_item_status not null default 'pendente',
  notes text,
  checked_by uuid references auth.users(id) on delete set null,
  checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(reservation_id, phase)
);

create table if not exists public.inventory_incidents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  event_id uuid references public.events(id) on delete set null,
  item_id uuid not null references public.inventory_items(id) on delete restrict,
  incident_type text not null check(incident_type in ('avaria','perda','manutencao','ajuste')),
  quantity numeric(12,3) not null default 1 check(quantity > 0),
  description text,
  resolved boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists inventory_items_company_idx on public.inventory_items(company_id, status);
create index if not exists inventory_reservations_item_period_idx on public.inventory_reservations(company_id, item_id, reserved_from, reserved_until);
create index if not exists inventory_reservations_event_idx on public.inventory_reservations(event_id, status);
create index if not exists inventory_checks_event_idx on public.inventory_checks(event_id, phase);

alter table public.inventory_categories enable row level security;
alter table public.inventory_items enable row level security;
alter table public.inventory_reservations enable row level security;
alter table public.inventory_checks enable row level security;
alter table public.inventory_incidents enable row level security;
revoke all on public.inventory_categories, public.inventory_items, public.inventory_reservations, public.inventory_checks, public.inventory_incidents from anon;
grant select, insert, update, delete on public.inventory_categories, public.inventory_items, public.inventory_reservations, public.inventory_checks, public.inventory_incidents to authenticated;

do $$ declare t text; begin
  foreach t in array array['inventory_categories','inventory_items','inventory_reservations','inventory_checks','inventory_incidents'] loop
    execute format('drop policy if exists %I on public.%I', t || '_select_member', t);
    execute format('create policy %I on public.%I for select to authenticated using (private.is_company_member(company_id))', t || '_select_member', t);
    execute format('drop policy if exists %I on public.%I', t || '_insert_member', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (private.is_company_member(company_id))', t || '_insert_member', t);
    execute format('drop policy if exists %I on public.%I', t || '_update_member', t);
    execute format('create policy %I on public.%I for update to authenticated using (private.is_company_member(company_id)) with check (private.is_company_member(company_id))', t || '_update_member', t);
    execute format('drop policy if exists %I on public.%I', t || '_delete_management', t);
    execute format('create policy %I on public.%I for delete to authenticated using (private.has_company_role(company_id, array[''proprietario'',''administrador'',''gerente'']::public.company_role[]))', t || '_delete_management', t);
  end loop;
end $$;

-- Disponibilidade real = estoque total - reservas que se sobrepõem ao período.
create or replace function public.inventory_availability(
  target_company_id uuid,
  target_item_id uuid,
  period_from timestamptz,
  period_until timestamptz,
  ignore_event_id uuid default null
)
returns numeric
language sql
stable
security invoker
set search_path = ''
as $$
  select case when i.track_quantity = false then 999999::numeric else
    greatest(0::numeric, i.total_quantity - coalesce((
      select sum(r.quantity)
      from public.inventory_reservations r
      where r.company_id = target_company_id
        and r.item_id = target_item_id
        and r.status in ('provisoria','confirmada','separada','em_uso')
        and (ignore_event_id is null or r.event_id <> ignore_event_id)
        and r.reserved_from < period_until
        and r.reserved_until > period_from
    ),0)) end
  from public.inventory_items i
  where i.id = target_item_id and i.company_id = target_company_id and i.status = 'ativo';
$$;

grant execute on function public.inventory_availability(uuid,uuid,timestamptz,timestamptz,uuid) to authenticated;

-- Reserva atômica: valida disponibilidade e impede overbooking por chamadas concorrentes do mesmo item.
create or replace function public.reserve_inventory_item(
  target_event_id uuid,
  target_item_id uuid,
  requested_quantity numeric,
  period_from timestamptz,
  period_until timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  ev public.events%rowtype;
  inv public.inventory_items%rowtype;
  available numeric;
  reservation_id uuid;
begin
  if requested_quantity <= 0 or period_until <= period_from then raise exception 'Reserva inválida'; end if;
  select * into ev from public.events where id = target_event_id;
  if not found or not private.is_company_member(ev.company_id) then raise exception 'Evento não encontrado'; end if;

  -- Serializa reservas concorrentes deste item.
  select * into inv from public.inventory_items where id = target_item_id and company_id = ev.company_id for update;
  if not found or inv.status <> 'ativo' then raise exception 'Item indisponível'; end if;

  available := public.inventory_availability(ev.company_id, inv.id, period_from, period_until, ev.id);
  if inv.track_quantity and available < requested_quantity then
    raise exception 'Conflito de estoque: disponível %, solicitado %', available, requested_quantity;
  end if;

  insert into public.inventory_reservations(company_id,event_id,item_id,quantity,reserved_from,reserved_until,status)
  values(ev.company_id,ev.id,inv.id,requested_quantity,period_from,period_until,'confirmada')
  on conflict(event_id,item_id) do update set
    quantity=excluded.quantity,reserved_from=excluded.reserved_from,reserved_until=excluded.reserved_until,status='confirmada',updated_at=now()
  returning id into reservation_id;
  return reservation_id;
end;
$$;

revoke all on function public.reserve_inventory_item(uuid,uuid,numeric,timestamptz,timestamptz) from public, anon;
grant execute on function public.reserve_inventory_item(uuid,uuid,numeric,timestamptz,timestamptz) to authenticated;

-- Gera checklist operacional diretamente das reservas confirmadas.
create or replace function public.prepare_event_inventory_check(target_event_id uuid, target_phase text)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare ev public.events%rowtype; affected integer;
begin
  if target_phase not in ('separacao','devolucao') then raise exception 'Fase inválida'; end if;
  select * into ev from public.events where id=target_event_id;
  if not found or not private.is_company_member(ev.company_id) then raise exception 'Evento não encontrado'; end if;

  insert into public.inventory_checks(company_id,event_id,reservation_id,phase,expected_quantity)
  select r.company_id,r.event_id,r.id,target_phase,r.quantity
  from public.inventory_reservations r
  where r.event_id=ev.id and r.status not in ('cancelada')
  on conflict(reservation_id,phase) do nothing;
  get diagnostics affected = row_count;
  return affected;
end;
$$;

revoke all on function public.prepare_event_inventory_check(uuid,text) from public, anon;
grant execute on function public.prepare_event_inventory_check(uuid,text) to authenticated;

create or replace view public.inventory_conflicts
with (security_invoker=true)
as
select r.company_id,r.event_id,r.item_id,i.name as item_name,r.quantity,r.reserved_from,r.reserved_until,
  public.inventory_availability(r.company_id,r.item_id,r.reserved_from,r.reserved_until,r.event_id) as available_excluding_event
from public.inventory_reservations r
join public.inventory_items i on i.id=r.item_id and i.company_id=r.company_id
where r.status in ('provisoria','confirmada','separada','em_uso')
  and i.track_quantity=true
  and public.inventory_availability(r.company_id,r.item_id,r.reserved_from,r.reserved_until,r.event_id) < r.quantity;

grant select on public.inventory_conflicts to authenticated;
