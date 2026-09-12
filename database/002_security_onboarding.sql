-- HEAVEN PLATAFORMA — BLOCO 2
-- Segurança multiempresa e onboarding.
-- Blueprint para Supabase/Postgres; aplicar somente após validação em projeto de desenvolvimento.

create schema if not exists private;

-- Perfil básico criado automaticamente quando um usuário nasce no Auth.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();
  return new;
end;
$$;

revoke all on function private.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_user();

-- Helpers usados pelas policies. Ficam fora do schema exposto.
create or replace function private.is_company_member(target_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.company_members cm
    where cm.company_id = target_company_id
      and cm.user_id = auth.uid()
      and cm.active = true
  );
$$;

create or replace function private.has_company_role(target_company_id uuid, allowed_roles public.company_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.company_members cm
    where cm.company_id = target_company_id
      and cm.user_id = auth.uid()
      and cm.active = true
      and cm.role = any(allowed_roles)
  );
$$;

revoke all on function private.is_company_member(uuid) from public, anon;
revoke all on function private.has_company_role(uuid, public.company_role[]) from public, anon;
grant execute on function private.is_company_member(uuid) to authenticated;
grant execute on function private.has_company_role(uuid, public.company_role[]) to authenticated;

-- Onboarding atômico: cria a empresa e torna o usuário atual proprietário.
create or replace function public.create_company_with_owner(
  company_name text,
  responsible_name text default null,
  company_email text default null,
  company_whatsapp text default null,
  company_city text default null,
  company_state text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_company_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  if nullif(trim(company_name), '') is null then
    raise exception 'Nome da empresa é obrigatório';
  end if;

  insert into public.companies (
    name, responsible_name, email, whatsapp, city, state
  ) values (
    trim(company_name),
    nullif(trim(responsible_name), ''),
    nullif(trim(company_email), ''),
    nullif(trim(company_whatsapp), ''),
    nullif(trim(company_city), ''),
    nullif(trim(company_state), '')
  ) returning id into new_company_id;

  insert into public.company_members (company_id, user_id, role, active)
  values (new_company_id, auth.uid(), 'proprietario', true);

  return new_company_id;
end;
$$;

revoke all on function public.create_company_with_owner(text,text,text,text,text,text) from public, anon;
grant execute on function public.create_company_with_owner(text,text,text,text,text,text) to authenticated;

-- Grants: RLS não substitui privilégios de tabela.
revoke all on public.companies, public.profiles, public.company_members,
  public.business_modalities, public.service_packages, public.business_rules
from anon;

grant select, update on public.profiles to authenticated;
grant select, update on public.companies to authenticated;
grant select, insert, update, delete on public.company_members to authenticated;
grant select, insert, update, delete on public.business_modalities to authenticated;
grant select, insert, update, delete on public.service_packages to authenticated;
grant select, insert, update, delete on public.business_rules to authenticated;

-- Perfis: usuário vê/edita somente o próprio perfil.
drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self on public.profiles
for select to authenticated
using (id = auth.uid());

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Empresa: qualquer membro ativo pode ler; gestão altera dados cadastrais.
drop policy if exists companies_select_member on public.companies;
create policy companies_select_member on public.companies
for select to authenticated
using (private.is_company_member(id));

drop policy if exists companies_update_management on public.companies;
create policy companies_update_management on public.companies
for update to authenticated
using (private.has_company_role(id, array['proprietario','administrador','gerente']::public.company_role[]))
with check (private.has_company_role(id, array['proprietario','administrador','gerente']::public.company_role[]));

-- Equipe: membros enxergam a equipe da própria empresa; somente proprietário/admin gerenciam.
drop policy if exists company_members_select_company on public.company_members;
create policy company_members_select_company on public.company_members
for select to authenticated
using (private.is_company_member(company_id));

drop policy if exists company_members_insert_admin on public.company_members;
create policy company_members_insert_admin on public.company_members
for insert to authenticated
with check (private.has_company_role(company_id, array['proprietario','administrador']::public.company_role[]));

drop policy if exists company_members_update_admin on public.company_members;
create policy company_members_update_admin on public.company_members
for update to authenticated
using (private.has_company_role(company_id, array['proprietario','administrador']::public.company_role[]))
with check (private.has_company_role(company_id, array['proprietario','administrador']::public.company_role[]));

drop policy if exists company_members_delete_admin on public.company_members;
create policy company_members_delete_admin on public.company_members
for delete to authenticated
using (private.has_company_role(company_id, array['proprietario','administrador']::public.company_role[]));

-- Configurações do negócio: leitura para equipe; escrita para gestão.
do $$
declare
  table_name text;
begin
  foreach table_name in array array['business_modalities','service_packages','business_rules']
  loop
    execute format('drop policy if exists %I on public.%I', table_name || '_select_member', table_name);
    execute format(
      'create policy %I on public.%I for select to authenticated using (private.is_company_member(company_id))',
      table_name || '_select_member', table_name
    );

    execute format('drop policy if exists %I on public.%I', table_name || '_insert_management', table_name);
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (private.has_company_role(company_id, array[''proprietario'',''administrador'',''gerente'']::public.company_role[]))',
      table_name || '_insert_management', table_name
    );

    execute format('drop policy if exists %I on public.%I', table_name || '_update_management', table_name);
    execute format(
      'create policy %I on public.%I for update to authenticated using (private.has_company_role(company_id, array[''proprietario'',''administrador'',''gerente'']::public.company_role[])) with check (private.has_company_role(company_id, array[''proprietario'',''administrador'',''gerente'']::public.company_role[]))',
      table_name || '_update_management', table_name
    );

    execute format('drop policy if exists %I on public.%I', table_name || '_delete_management', table_name);
    execute format(
      'create policy %I on public.%I for delete to authenticated using (private.has_company_role(company_id, array[''proprietario'',''administrador'']::public.company_role[]))',
      table_name || '_delete_management', table_name
    );
  end loop;
end $$;

-- Proteção adicional: não permitir que um admin remova/reescreva o último proprietário
-- será tratada por RPC dedicada no bloco de gestão de equipe, evitando lógica sensível no cliente.
