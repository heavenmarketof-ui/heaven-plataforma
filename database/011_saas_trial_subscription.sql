-- HEAVEN PLATAFORMA — TRIAL + ASSINATURA SAAS
-- Regra comercial atual: 15 dias grátis; após o trial, ativação R$ 1.000 + mensalidade R$ 99,90.
-- Valores ficam versionados no plano para permitir mudanças futuras sem alterar contratos antigos.

do $$ begin
 create type public.subscription_status as enum ('trial','aguardando_pagamento','ativa','inadimplente','suspensa','cancelada');
exception when duplicate_object then null; end $$;

alter table public.companies add column if not exists trial_started_at timestamptz;
alter table public.companies add column if not exists trial_ends_at timestamptz;
alter table public.companies add column if not exists access_blocked_at timestamptz;

create table if not exists public.saas_plans(
 id uuid primary key default gen_random_uuid(),
 code text not null unique,
 name text not null,
 trial_days integer not null default 15 check(trial_days>=0),
 setup_fee numeric(12,2) not null default 1000 check(setup_fee>=0),
 monthly_fee numeric(12,2) not null default 99.90 check(monthly_fee>=0),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

insert into public.saas_plans(code,name,trial_days,setup_fee,monthly_fee)
values('heaven-standard','Heaven Plataforma',15,1000,99.90)
on conflict(code) do update set trial_days=excluded.trial_days,setup_fee=excluded.setup_fee,monthly_fee=excluded.monthly_fee,updated_at=now();

create table if not exists public.company_subscriptions(
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null unique references public.companies(id) on delete cascade,
 plan_id uuid not null references public.saas_plans(id),
 status public.subscription_status not null default 'trial',
 trial_started_at timestamptz not null default now(),
 trial_ends_at timestamptz not null,
 setup_fee numeric(12,2) not null,
 monthly_fee numeric(12,2) not null,
 setup_paid_at timestamptz,
 current_period_start date,
 current_period_end date,
 next_billing_date date,
 payment_provider text,
 provider_customer_id text,
 provider_subscription_id text,
 activated_at timestamptz,
 suspended_at timestamptz,
 cancelled_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists company_subscriptions_status_idx on public.company_subscriptions(status,trial_ends_at);
alter table public.saas_plans enable row level security;
alter table public.company_subscriptions enable row level security;
revoke all on public.company_subscriptions from anon;
grant select on public.saas_plans to anon,authenticated;
grant select on public.company_subscriptions to authenticated;

create policy saas_plans_public_read on public.saas_plans for select using(active=true);
create policy company_subscription_member_read on public.company_subscriptions for select to authenticated using(private.is_company_member(company_id));

-- Chamado imediatamente após criação da empresa no onboarding.
create or replace function public.start_company_trial(target_company_id uuid)
returns uuid language plpgsql security definer set search_path=''
as $$
declare p public.saas_plans%rowtype; sid uuid; started timestamptz:=now(); ends_at timestamptz;
begin
 if not private.has_company_role(target_company_id,array['proprietario']::public.company_role[]) then raise exception 'Não autorizado'; end if;
 select * into p from public.saas_plans where code='heaven-standard' and active=true;
 if not found then raise exception 'Plano Heaven indisponível'; end if;
 if exists(select 1 from public.company_subscriptions where company_id=target_company_id) then
   select id into sid from public.company_subscriptions where company_id=target_company_id; return sid;
 end if;
 ends_at:=started+make_interval(days=>p.trial_days);
 insert into public.company_subscriptions(company_id,plan_id,status,trial_started_at,trial_ends_at,setup_fee,monthly_fee)
 values(target_company_id,p.id,'trial',started,ends_at,p.setup_fee,p.monthly_fee) returning id into sid;
 update public.companies set status='trial',trial_started_at=started,trial_ends_at=ends_at,updated_at=now() where id=target_company_id;
 return sid;
end;$$;
revoke all on function public.start_company_trial(uuid) from public,anon;
grant execute on function public.start_company_trial(uuid) to authenticated;

-- O backend/UI usa esta função para decidir se o tenant pode entrar no ERP.
create or replace function public.company_access_state(target_company_id uuid)
returns jsonb language plpgsql stable security invoker set search_path=''
as $$
declare s public.company_subscriptions%rowtype; allowed boolean; days_left integer;
begin
 if not private.is_company_member(target_company_id) then raise exception 'Não autorizado'; end if;
 select * into s from public.company_subscriptions where company_id=target_company_id;
 if not found then return jsonb_build_object('allowed',false,'reason','subscription_missing'); end if;
 days_left:=greatest(ceil(extract(epoch from(s.trial_ends_at-now()))/86400)::integer,0);
 allowed:=(s.status='ativa') or (s.status='trial' and now()<s.trial_ends_at);
 return jsonb_build_object('allowed',allowed,'status',s.status,'trial_ends_at',s.trial_ends_at,'trial_days_left',days_left,'setup_fee',s.setup_fee,'monthly_fee',s.monthly_fee,'next_billing_date',s.next_billing_date);
end;$$;
grant execute on function public.company_access_state(uuid) to authenticated;
