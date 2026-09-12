-- HEAVEN PLATAFORMA — EVENTOS, AGENDA E OPERAÇÃO
-- Contrato ativo -> evento operacional -> tarefas/agenda.

do $$ begin
  create type public.event_status as enum ('planejamento','confirmado','em_preparacao','em_execucao','aguardando_devolucao','concluido','cancelado');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.operation_type as enum ('retirada','entrega','montagem','desmontagem','devolucao','conferencia','outro');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.task_status as enum ('pendente','em_andamento','concluida','cancelada');
exception when duplicate_object then null; end $$;

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  contract_id uuid not null references public.contracts(id) on delete restrict,
  client_id uuid not null references public.clients(id) on delete restrict,
  title text not null,
  event_type text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  venue_name text,
  address text,
  city text,
  state text,
  status public.event_status not null default 'planejamento',
  responsible_user_id uuid references auth.users(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, contract_id),
  check (ends_at is null or ends_at >= starts_at)
);

create table if not exists public.event_operations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  operation_type public.operation_type not null,
  scheduled_at timestamptz,
  scheduled_end_at timestamptz,
  address text,
  responsible_user_id uuid references auth.users(id) on delete set null,
  status public.task_status not null default 'pendente',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (scheduled_end_at is null or scheduled_at is null or scheduled_end_at >= scheduled_at)
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  event_id uuid references public.events(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete cascade,
  assigned_user_id uuid references auth.users(id) on delete set null,
  title text not null,
  description text,
  due_at timestamptz,
  priority smallint not null default 2 check (priority between 1 and 3),
  status public.task_status not null default 'pendente',
  action_type text,
  action_payload jsonb not null default '{}'::jsonb,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists events_company_start_idx on public.events(company_id, starts_at);
create index if not exists events_company_status_idx on public.events(company_id, status);
create index if not exists event_operations_schedule_idx on public.event_operations(company_id, scheduled_at);
create index if not exists tasks_company_due_idx on public.tasks(company_id, due_at) where status in ('pendente','em_andamento');
create index if not exists tasks_assigned_idx on public.tasks(company_id, assigned_user_id, status);

alter table public.events enable row level security;
alter table public.event_operations enable row level security;
alter table public.tasks enable row level security;
revoke all on public.events, public.event_operations, public.tasks from anon;
grant select, insert, update, delete on public.events, public.event_operations, public.tasks to authenticated;

do $$
declare t text;
begin
  foreach t in array array['events','event_operations','tasks'] loop
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

-- Evento é criado a partir do snapshot contratual, sem novo cadastro paralelo.
create or replace function public.activate_contract_and_create_event(target_contract_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  ct public.contracts%rowtype;
  event_id uuid;
  event_date date;
  event_title text;
  event_city text;
  event_state text;
  event_address text;
begin
  select * into ct from public.contracts where id = target_contract_id;
  if not found or not private.is_company_member(ct.company_id) then raise exception 'Contrato não encontrado'; end if;

  event_date := nullif(ct.event_snapshot ->> 'date', '')::date;
  if event_date is null then raise exception 'Contrato sem data de evento'; end if;
  event_title := coalesce(nullif(ct.event_snapshot ->> 'type',''), 'Evento') || ' - ' || coalesce(nullif(ct.customer_snapshot ->> 'name',''), 'Cliente');
  event_city := ct.event_snapshot ->> 'city';
  event_state := ct.event_snapshot ->> 'state';
  event_address := ct.event_snapshot ->> 'address';

  insert into public.events(company_id, contract_id, client_id, title, event_type, starts_at, address, city, state, status)
  values(ct.company_id, ct.id, ct.client_id, event_title, ct.event_snapshot ->> 'type', event_date::timestamp, event_address, event_city, event_state, 'confirmado')
  on conflict (company_id, contract_id) do update set updated_at = now()
  returning id into event_id;

  update public.contracts set status = 'ativo', updated_at = now() where id = ct.id;
  return event_id;
end;
$$;

revoke all on function public.activate_contract_and_create_event(uuid) from public, anon;
grant execute on function public.activate_contract_and_create_event(uuid) to authenticated;

-- Fila unificada para a tela Hoje. Mantém a Home operacional, não uma duplicação dos módulos.
create or replace view public.today_actions
with (security_invoker = true)
as
select
  t.company_id,
  'task'::text as source_type,
  t.id as source_id,
  t.title,
  t.description,
  t.due_at as scheduled_at,
  t.priority,
  t.action_type,
  t.action_payload,
  t.assigned_user_id
from public.tasks t
where t.status in ('pendente','em_andamento')
union all
select
  eo.company_id,
  'operation'::text,
  eo.id,
  initcap(replace(eo.operation_type::text, '_', ' ')),
  eo.notes,
  eo.scheduled_at,
  2,
  'open_event'::text,
  jsonb_build_object('event_id', eo.event_id),
  eo.responsible_user_id
from public.event_operations eo
where eo.status in ('pendente','em_andamento');

grant select on public.today_actions to authenticated;
