-- ReplayGO Supabase schema
-- Executar no SQL Editor do seu projeto Supabase (modo `public`).

-- Extensões necessárias -------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- Tipos customizados ----------------------------------------------------------
create type public.arena_status as enum ('active', 'inactive');
create type public.replay_visibility as enum ('public', 'expired');

-- Função utilitária para updated_at -------------------------------------------
create or replace function public.set_current_timestamp_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

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

create trigger set_timestamp_profiles
before update on public.profiles
for each row execute function public.set_current_timestamp_updated_at();

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

create trigger set_timestamp_arenas
before update on public.arenas
for each row execute function public.set_current_timestamp_updated_at();

-- QUADRAS ---------------------------------------------------------------------
create table if not exists public.courts (
  id uuid primary key default uuid_generate_v4(),
  arena_id uuid not null references public.arenas(id) on delete cascade,
  name text not null,
  is_live boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_timestamp_courts
before update on public.courts
for each row execute function public.set_current_timestamp_updated_at();

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

create trigger set_timestamp_replays
before update on public.replays
for each row execute function public.set_current_timestamp_updated_at();

-- REPLAYS SALVOS --------------------------------------------------------------
create table if not exists public.saved_replays (
  id uuid primary key default uuid_generate_v4(),
  replay_id uuid not null references public.replays(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create unique index if not exists saved_replays_unique
on public.saved_replays (replay_id, user_id);

-- RLS -------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.arenas enable row level security;
alter table public.courts enable row level security;
alter table public.replays enable row level security;
alter table public.saved_replays enable row level security;

-- Perfis: cada usuário acessa o próprio registro -------------------------------
create policy if not exists "Profiles are viewable by owner"
on public.profiles for select
using (auth.uid() = id)
with check (auth.uid() = id);

create policy if not exists "Profiles are editable by owner"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy if not exists "Admins manage all profiles"
on public.profiles for all
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

-- Arenas: leitura autenticada, owners/admin gerenciam -------------------------
create policy if not exists "Authenticated read arenas"
on public.arenas for select
using (auth.role() = 'authenticated');

create policy if not exists "Owners manage own arenas"
on public.arenas for all
using (
  owner_id = auth.uid()
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  owner_id = auth.uid()
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

-- Courts ----------------------------------------------------------------------
create policy if not exists "Authenticated read courts"
on public.courts for select
using (auth.role() = 'authenticated');

create policy if not exists "Owners manage own courts"
on public.courts for all
using (
  exists (
    select 1 from public.arenas a
    where a.id = arena_id
      and (a.owner_id = auth.uid()
        or exists (
          select 1 from public.profiles p
          where p.id = auth.uid() and p.role = 'admin'
        )
      )
  )
)
with check (
  exists (
    select 1 from public.arenas a
    where a.id = arena_id
      and (a.owner_id = auth.uid()
        or exists (
          select 1 from public.profiles p
          where p.id = auth.uid() and p.role = 'admin'
        )
      )
  )
);

-- Replays ---------------------------------------------------------------------
create policy if not exists "Authenticated read replays"
on public.replays for select
using (
  auth.role() = 'authenticated'
);

create policy if not exists "Owners manage own replays"
on public.replays for all
using (
  owner_id = auth.uid()
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  owner_id = auth.uid()
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

-- Saved replays ----------------------------------------------------------------
create policy if not exists "Users manage own saved replays"
on public.saved_replays for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- TRIGGER PARA PERFIS ---------------------------------------------------------
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
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- =============================================================================
-- MIGRAÇÃO: automatização do painel admin (coluna uf + tabela cities)
-- Idempotente — seguro reexecutar.
-- =============================================================================

-- 1) Arenas ganham UF (usada nos carrosséis por cidade) ----------------------
alter table public.arenas
  add column if not exists uf text not null default '';

-- 2) Tabela de cidades --------------------------------------------------------
create table if not exists public.cities (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  uf text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Evita cidades duplicadas (mesmo nome+UF, ignorando caixa).
create unique index if not exists cities_name_uf_unique
  on public.cities (lower(name), lower(uf));

drop trigger if exists set_timestamp_cities on public.cities;
create trigger set_timestamp_cities
before update on public.cities
for each row execute function public.set_current_timestamp_updated_at();

-- 3) RLS de cidades: leitura autenticada, escrita só para admin --------------
alter table public.cities enable row level security;

drop policy if exists "Authenticated read cities" on public.cities;
create policy "Authenticated read cities"
on public.cities for select
using (auth.role() = 'authenticated');

drop policy if exists "Admins manage cities" on public.cities;
create policy "Admins manage cities"
on public.cities for all
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

-- 4) Seed inicial de cidades (apenas se a tabela estiver vazia) ---------------
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

-- Seeds opcionais -------------------------------------------------------------
-- Exemplos: inserir arenas iniciais, quadras e replays mockados se necessário.
-- Utilize os IDs gerados pelo app ou deixe para criar via scripts dedicados.
