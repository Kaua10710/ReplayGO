-- ReplayGO Supabase schema (idempotente)
-- Rode no SQL Editor do seu projeto Supabase (schema `public`).
-- Pode ser reexecutado com segurança num banco vazio ou parcialmente aplicado.

-- Extensões necessárias -------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- Tipos customizados (idempotente) --------------------------------------------
do $$
begin
  create type public.arena_status as enum ('active', 'inactive');
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create type public.replay_visibility as enum ('public', 'expired');
exception
  when duplicate_object then null;
end $$;

-- Função utilitária para updated_at -------------------------------------------
create or replace function public.set_current_timestamp_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- =============================================================================
-- TABELAS
-- =============================================================================

-- PERFIS ----------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  name text not null,
  role text not null check (role in ('user', 'owner', 'admin')),
  sport text,
  notifications integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ARENAS ----------------------------------------------------------------------
create table if not exists public.arenas (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid references public.profiles(id) on delete set null,
  name text not null,
  city text not null,
  status public.arena_status not null default 'active',
  is_live boolean not null default false,
  replay_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Coluna usada nos carrosséis por cidade (UF).
alter table public.arenas
  add column if not exists uf text not null default '';

-- QUADRAS ---------------------------------------------------------------------
create table if not exists public.courts (
  id uuid primary key default uuid_generate_v4(),
  arena_id uuid not null references public.arenas(id) on delete cascade,
  name text not null,
  is_live boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- REPLAYS ---------------------------------------------------------------------
create table if not exists public.replays (
  id uuid primary key default uuid_generate_v4(),
  arena_id uuid not null references public.arenas(id) on delete cascade,
  court_id uuid references public.courts(id) on delete set null,
  owner_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text,
  duration_seconds integer not null default 0,
  recorded_at timestamptz not null default now(),
  visibility public.replay_visibility not null default 'public',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- REPLAYS SALVOS --------------------------------------------------------------
create table if not exists public.saved_replays (
  id uuid primary key default uuid_generate_v4(),
  replay_id uuid not null references public.replays(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create unique index if not exists saved_replays_unique
on public.saved_replays (replay_id, user_id);

-- CIDADES ---------------------------------------------------------------------
create table if not exists public.cities (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  uf text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists cities_name_uf_unique
on public.cities (lower(name), lower(uf));

-- =============================================================================
-- TRIGGERS de updated_at (drop+create = idempotente)
-- =============================================================================
drop trigger if exists set_timestamp_profiles on public.profiles;
create trigger set_timestamp_profiles
before update on public.profiles
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_timestamp_arenas on public.arenas;
create trigger set_timestamp_arenas
before update on public.arenas
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_timestamp_courts on public.courts;
create trigger set_timestamp_courts
before update on public.courts
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_timestamp_replays on public.replays;
create trigger set_timestamp_replays
before update on public.replays
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_timestamp_cities on public.cities;
create trigger set_timestamp_cities
before update on public.cities
for each row execute function public.set_current_timestamp_updated_at();

-- =============================================================================
-- is_admin(): evita recursão de RLS em profiles.
-- SECURITY DEFINER + search_path fixo: consulta profiles SEM passar pela RLS.
-- =============================================================================
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated, anon, service_role;

-- =============================================================================
-- RLS
-- =============================================================================
alter table public.profiles enable row level security;
alter table public.arenas enable row level security;
alter table public.courts enable row level security;
alter table public.replays enable row level security;
alter table public.saved_replays enable row level security;
alter table public.cities enable row level security;

-- Limpeza de policies antigas (inclui a versão recursiva problemática) --------
drop policy if exists "Profiles are viewable by owner" on public.profiles;
drop policy if exists "Profiles are editable by owner" on public.profiles;
drop policy if exists "Admins manage all profiles" on public.profiles;

-- Perfis ----------------------------------------------------------------------
-- Leitura: o próprio usuário ou um admin (via is_admin, sem recursão).
create policy "Profiles are viewable by owner or admin"
on public.profiles for select
using (auth.uid() = id or public.is_admin());

-- Atualização: somente o próprio usuário.
create policy "Profiles are editable by owner"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- Admin gerencia todos os perfis (sem auto-referência recursiva).
create policy "Admins manage all profiles"
on public.profiles for all
using (public.is_admin())
with check (public.is_admin());

-- Arenas ----------------------------------------------------------------------
drop policy if exists "Authenticated read arenas" on public.arenas;
create policy "Authenticated read arenas"
on public.arenas for select
using (auth.role() = 'authenticated');

drop policy if exists "Owners manage own arenas" on public.arenas;
create policy "Owners manage own arenas"
on public.arenas for all
using (owner_id = auth.uid() or public.is_admin())
with check (owner_id = auth.uid() or public.is_admin());

-- Courts ----------------------------------------------------------------------
drop policy if exists "Authenticated read courts" on public.courts;
create policy "Authenticated read courts"
on public.courts for select
using (auth.role() = 'authenticated');

drop policy if exists "Owners manage own courts" on public.courts;
create policy "Owners manage own courts"
on public.courts for all
using (
  public.is_admin()
  or exists (
    select 1 from public.arenas a
    where a.id = arena_id and a.owner_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.arenas a
    where a.id = arena_id and a.owner_id = auth.uid()
  )
);

-- Replays ---------------------------------------------------------------------
drop policy if exists "Authenticated read replays" on public.replays;
create policy "Authenticated read replays"
on public.replays for select
using (auth.role() = 'authenticated');

drop policy if exists "Owners manage own replays" on public.replays;
create policy "Owners manage own replays"
on public.replays for all
using (owner_id = auth.uid() or public.is_admin())
with check (owner_id = auth.uid() or public.is_admin());

-- Saved replays ---------------------------------------------------------------
drop policy if exists "Users manage own saved replays" on public.saved_replays;
create policy "Users manage own saved replays"
on public.saved_replays for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Cidades ---------------------------------------------------------------------
drop policy if exists "Authenticated read cities" on public.cities;
create policy "Authenticated read cities"
on public.cities for select
using (auth.role() = 'authenticated');

drop policy if exists "Admins manage cities" on public.cities;
create policy "Admins manage cities"
on public.cities for all
using (public.is_admin())
with check (public.is_admin());

-- =============================================================================
-- TRIGGER: cria o profile automaticamente quando um usuário é criado em auth
-- =============================================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'user')
  )
  on conflict (id) do update set
    email = excluded.email,
    name = excluded.name,
    role = excluded.role,
    updated_at = now();

  return new;
end;
$$ language plpgsql security definer set search_path = public;

create or replace trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Backfill: cria profiles para usuários que já existiam ANTES do trigger
-- (ex.: contas criadas enquanto o schema antigo estava quebrado).
insert into public.profiles (id, email, name, role)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'name', split_part(u.email, '@', 1)),
  coalesce(u.raw_user_meta_data->>'role', 'user')
from auth.users u
where u.email is not null
  and not exists (select 1 from public.profiles p where p.id = u.id);

-- =============================================================================
-- SEED: cidades iniciais (apenas se a tabela estiver vazia)
-- =============================================================================
insert into public.cities (name, uf)
select v.name, v.uf
from (values
  ('Fortaleza', 'CE'),
  ('Recife', 'PE'),
  ('Florianópolis', 'SC'),
  ('Salvador', 'BA'),
  ('Rio de Janeiro', 'RJ'),
  ('Porto Alegre', 'RS')
) as v(name, uf)
where not exists (select 1 from public.cities);
