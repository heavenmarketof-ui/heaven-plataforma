-- HEAVEN PLATAFORMA — BLOCO CRM COMERCIAL
-- Lead -> Orçamento -> Cliente sem redigitação.

do $$ begin
  create type public.quote_status as enum ('rascunho','enviado','aprovado','recusado','expirado','cancelado');
exception when duplicate_object then null; end $$;

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id) on delete cascade,
  source_lead_id uuid references public.leads(id) on delete set null, name text not null, phone text, email text, document text,
  address text, city text, state text, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(company_id, source_lead_id)
);
create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete set null, client_id uuid references public.clients(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null, assigned_user_id uuid references auth.users(id) on delete set null,
  title text not null default 'Orçamento', event_type text, event_date date, event_address text, event_city text, event_state text,
  status public.quote_status not null default 'rascunho', subtotal numeric(12,2) not null default 0, discount numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0, valid_until date, customer_notes text, internal_notes text, sent_at timestamptz,
  approved_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.quote_items (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id) on delete cascade,
  quote_id uuid not null references public.quotes(id) on delete cascade,
  item_type text not null default 'servico' check (item_type in ('item','kit','servico','montagem','transporte','adicional','outro')),
  reference_id uuid, description text not null, quantity numeric(12,3) not null default 1 check (quantity > 0), unit_price numeric(12,2) not null default 0,
  total numeric(12,2) generated always as (round(quantity * unit_price, 2)) stored, display_order integer not null default 0, created_at timestamptz not null default now()
);
create table if not exists public.lead_activities (
  id uuid primary key default gen_random_uuid(), company_id uuid not null references public.companies(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade, user_id uuid references auth.users(id) on delete set null,
  activity_type text not null check (activity_type in ('criacao','contato','nota','status','tarefa','orcamento','conversao')),
  description text not null, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists clients_company_name_idx on public.clients(company_id, name);
create index if not exists quotes_company_status_idx on public.quotes(company_id, status);
create index if not exists quotes_company_event_idx on public.quotes(company_id, event_date);
create index if not exists quote_items_quote_idx on public.quote_items(quote_id, display_order);
create index if not exists lead_activities_lead_idx on public.lead_activities(lead_id, created_at desc);
alter table public.clients enable row level security; alter table public.quotes enable row level security; alter table public.quote_items enable row level security; alter table public.lead_activities enable row level security;
revoke all on public.clients, public.quotes, public.quote_items, public.lead_activities from anon;
grant select, insert, update, delete on public.clients, public.quotes, public.quote_items, public.lead_activities to authenticated;
do $$ declare t text; begin
  foreach t in array array['clients','quotes','quote_items','lead_activities'] loop
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
create or replace function public.create_quote_from_lead(target_lead_id uuid) returns uuid language plpgsql security definer set search_path = '' as $$
declare source_lead public.leads%rowtype; new_quote_id uuid;
begin
  select * into source_lead from public.leads where id = target_lead_id;
  if not found or not private.is_company_member(source_lead.company_id) then raise exception 'Lead não encontrado'; end if;
  insert into public.quotes(company_id,lead_id,created_by,assigned_user_id,title,event_type,event_date,event_city)
  values(source_lead.company_id,source_lead.id,auth.uid(),source_lead.assigned_user_id,coalesce('Orçamento - ' || nullif(source_lead.name,''),'Orçamento'),source_lead.event_type,source_lead.event_date,source_lead.city)
  returning id into new_quote_id;
  update public.leads set status='orcamento',updated_at=now() where id=source_lead.id;
  insert into public.lead_activities(company_id,lead_id,user_id,activity_type,description,metadata) values(source_lead.company_id,source_lead.id,auth.uid(),'orcamento','Orçamento criado a partir do lead',jsonb_build_object('quote_id',new_quote_id));
  return new_quote_id;
end; $$;
revoke all on function public.create_quote_from_lead(uuid) from public, anon; grant execute on function public.create_quote_from_lead(uuid) to authenticated;

-- Usa resolved_client_id para nunca confundir a variável PL/pgSQL com a coluna quotes.client_id.
create or replace function public.convert_lead_to_client(target_lead_id uuid) returns uuid language plpgsql security definer set search_path = '' as $$
declare source_lead public.leads%rowtype; resolved_client_id uuid;
begin
  select * into source_lead from public.leads where id = target_lead_id;
  if not found or not private.is_company_member(source_lead.company_id) then raise exception 'Lead não encontrado'; end if;
  select c.id into resolved_client_id from public.clients c where c.company_id=source_lead.company_id and c.source_lead_id=source_lead.id;
  if resolved_client_id is null then
    insert into public.clients(company_id,source_lead_id,name,phone,email,city,notes)
    values(source_lead.company_id,source_lead.id,source_lead.name,source_lead.phone,source_lead.email,source_lead.city,source_lead.notes)
    returning id into resolved_client_id;
  end if;
  update public.quotes q set client_id=resolved_client_id,updated_at=now()
  where q.company_id=source_lead.company_id and q.lead_id=source_lead.id and q.client_id is null;
  update public.leads set status='ganho',won_at=coalesce(won_at,now()),updated_at=now() where id=source_lead.id;
  insert into public.lead_activities(company_id,lead_id,user_id,activity_type,description,metadata)
  values(source_lead.company_id,source_lead.id,auth.uid(),'conversao','Lead convertido em cliente',jsonb_build_object('client_id',resolved_client_id));
  return resolved_client_id;
end; $$;
revoke all on function public.convert_lead_to_client(uuid) from public, anon; grant execute on function public.convert_lead_to_client(uuid) to authenticated;
