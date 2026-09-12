-- HEAVEN PLATAFORMA — CRM / LEADS
-- Estrutura genérica para qualquer tenant. Nenhum campo/regra pertence à LHL.

do $$ begin
  create type public.lead_status as enum ('novo','em_atendimento','orcamento','negociacao','ganho','perdido');
exception when duplicate_object then null; end $$;

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  assigned_user_id uuid references auth.users(id) on delete set null,
  name text not null,
  phone text,
  email text,
  source text,
  event_type text,
  event_date date,
  city text,
  notes text,
  status public.lead_status not null default 'novo',
  next_action_at timestamptz,
  first_contact_at timestamptz,
  won_at timestamptz,
  lost_at timestamptz,
  lost_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists leads_company_status_idx on public.leads(company_id, status);
create index if not exists leads_company_created_idx on public.leads(company_id, created_at desc);
create index if not exists leads_assigned_idx on public.leads(company_id, assigned_user_id);
create index if not exists leads_next_action_idx on public.leads(company_id, next_action_at);

alter table public.leads enable row level security;
revoke all on public.leads from anon;
grant select, insert, update, delete on public.leads to authenticated;

drop policy if exists leads_select_member on public.leads;
create policy leads_select_member on public.leads
for select to authenticated
using (private.is_company_member(company_id));

drop policy if exists leads_insert_member on public.leads;
create policy leads_insert_member on public.leads
for insert to authenticated
with check (private.is_company_member(company_id));

drop policy if exists leads_update_member on public.leads;
create policy leads_update_member on public.leads
for update to authenticated
using (private.is_company_member(company_id))
with check (private.is_company_member(company_id));

drop policy if exists leads_delete_management on public.leads;
create policy leads_delete_management on public.leads
for delete to authenticated
using (private.has_company_role(company_id, array['proprietario','administrador','gerente']::public.company_role[]));

-- A tela Hoje consulta apenas pendências acionáveis; lead ganho/perdido deixa de gerar alerta.
create or replace view public.actionable_leads
with (security_invoker = true)
as
select
  id, company_id, assigned_user_id, name, phone, email, source,
  event_type, event_date, city, status, next_action_at, created_at
from public.leads
where status not in ('ganho','perdido');

grant select on public.actionable_leads to authenticated;
