-- HEAVEN PLATAFORMA — BLOCO 1
-- Blueprint versionado do núcleo SaaS. Ainda não aplicado em produção.
-- Todas as tabelas operacionais devem carregar company_id.

create extension if not exists pgcrypto;

do $$ begin
  create type public.company_role as enum ('proprietario','administrador','gerente','equipe');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.company_status as enum ('trial','ativa','suspensa','cancelada');
exception when duplicate_object then null; end $$;

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  document text,
  responsible_name text,
  email text,
  whatsapp text,
  instagram text,
  city text,
  state text,
  status public.company_status not null default 'trial',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.company_role not null default 'equipe',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id,user_id)
);

create index if not exists company_members_company_idx on public.company_members(company_id);
create index if not exists company_members_user_idx on public.company_members(user_id);

-- Modalidades criadas pela própria decoradora.
create table if not exists public.business_modalities (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  description text,
  active boolean not null default true,
  display_order integer not null default 0,
  requires_pickup boolean not null default false,
  requires_return boolean not null default false,
  allows_delivery boolean not null default false,
  includes_setup boolean not null default false,
  includes_teardown boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id,name)
);
create index if not exists business_modalities_company_idx on public.business_modalities(company_id);

-- Kits/planos: nomes e preços pertencem à empresa, nunca à Heaven globalmente.
create table if not exists public.service_packages (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  modality_id uuid references public.business_modalities(id) on delete set null,
  name text not null,
  description text,
  suggested_price numeric(12,2),
  allow_manual_price boolean not null default true,
  active boolean not null default true,
  display_order integer not null default 0,
  customer_notes text,
  internal_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id,name)
);
create index if not exists service_packages_company_idx on public.service_packages(company_id);
create index if not exists service_packages_modality_idx on public.service_packages(modality_id);

-- Regras comerciais configuráveis. Campos essenciais ficam estruturados.
create table if not exists public.business_rules (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  modality_id uuid references public.business_modalities(id) on delete cascade,
  package_id uuid references public.service_packages(id) on delete cascade,
  signal_type text not null default 'percent' check (signal_type in ('percent','fixed','manual')),
  signal_value numeric(12,2),
  final_payment_days_before integer,
  quote_validity_days integer,
  reservation_confirmation text not null default 'signal' check (reservation_confirmation in ('signal','contract','manual')),
  deposit_mode text not null default 'none' check (deposit_mode in ('none','fixed','manual')),
  deposit_value numeric(12,2),
  late_fee_value numeric(12,2),
  cancellation_policy text,
  extra_rules jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (not (modality_id is not null and package_id is not null))
);
create index if not exists business_rules_company_idx on public.business_rules(company_id);
create index if not exists business_rules_modality_idx on public.business_rules(modality_id);
create index if not exists business_rules_package_idx on public.business_rules(package_id);

-- Segurança multiempresa. A versão definitiva será validada em projeto Supabase de desenvolvimento.
alter table public.companies enable row level security;
alter table public.profiles enable row level security;
alter table public.company_members enable row level security;
alter table public.business_modalities enable row level security;
alter table public.service_packages enable row level security;
alter table public.business_rules enable row level security;

-- Observação: policies/RPCs serão adicionadas no bloco de segurança após conexão
-- do projeto Supabase. Não publicar tabelas sem RLS/policies/grants validados.
