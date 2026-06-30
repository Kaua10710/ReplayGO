-- ReplayGO — seed das contas de teste (idempotente)
-- Rode DEPOIS de schema.sql.
--
-- Cria/garante 3 usuários já com e-mail confirmado (senha: Test@1234):
--   lucas@replaygo.com  -> role user
--   arena@replaygo.com  -> role owner
--   admin@replaygo.com  -> role admin
--
-- Observação: escrever direto em auth.users/auth.identities é sensível à versão
-- do GoTrue. Este bloco é defensivo (só insere o que falta). Se mesmo assim
-- falhar na sua versão, use o CAMINHO ALTERNATIVO no fim do arquivo (Dashboard).

create extension if not exists pgcrypto;

do $$
declare
  rec record;
  v_user_id uuid;
begin
  for rec in
    select * from (values
      ('lucas@replaygo.com', 'Lucas Carvalho', 'user'),
      ('arena@replaygo.com', 'Arena Beira Mar', 'owner'),
      ('admin@replaygo.com', 'Admin ReplayGO', 'admin')
    ) as t(email, full_name, role)
  loop
    -- Já existe esse usuário no auth?
    select id into v_user_id from auth.users where email = rec.email;

    -- 1) auth.users (apenas se ainda não existir) -----------------------------
    if v_user_id is null then
      v_user_id := gen_random_uuid();

      insert into auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at
      ) values (
        '00000000-0000-0000-0000-000000000000',
        v_user_id,
        'authenticated',
        'authenticated',
        rec.email,
        crypt('Test@1234', gen_salt('bf')),
        now(),
        jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
        jsonb_build_object('name', rec.full_name, 'role', rec.role),
        now(),
        now()
      );
    end if;

    -- 2) auth.identities (provider 'email'; provider_id é NOT NULL em versões
    --    novas — usamos o id do usuário como texto) ----------------------------
    if not exists (
      select 1 from auth.identities
      where user_id = v_user_id and provider = 'email'
    ) then
      insert into auth.identities (
        id,
        user_id,
        provider_id,
        provider,
        identity_data,
        last_sign_in_at,
        created_at,
        updated_at
      ) values (
        gen_random_uuid(),
        v_user_id,
        v_user_id::text,
        'email',
        jsonb_build_object(
          'sub', v_user_id::text,
          'email', rec.email,
          'email_verified', true
        ),
        now(),
        now(),
        now()
      );
    end if;

    -- 3) profile com o role correto (o trigger handle_new_user já cria; aqui
    --    reforçamos/garantimos o papel) ----------------------------------------
    insert into public.profiles (id, email, name, role)
    values (v_user_id, rec.email, rec.full_name, rec.role)
    on conflict (id) do update set
      email = excluded.email,
      name = excluded.name,
      role = excluded.role,
      updated_at = now();
  end loop;
end $$;

-- ============================================================================
-- CAMINHO ALTERNATIVO (mais seguro se o bloco acima falhar na sua versão)
-- ----------------------------------------------------------------------------
-- 1. No Dashboard: Authentication -> Users -> Add user, criando os 3 e-mails
--    com senha Test@1234 e marcando "Auto Confirm User".
-- 2. Rode SOMENTE o bloco abaixo para definir os papéis (idempotente):
--
-- insert into public.profiles (id, email, name, role)
-- select u.id,
--        u.email,
--        coalesce(u.raw_user_meta_data->>'name', m.full_name),
--        m.role
-- from auth.users u
-- join (values
--   ('lucas@replaygo.com', 'Lucas Carvalho', 'user'),
--   ('arena@replaygo.com', 'Arena Beira Mar', 'owner'),
--   ('admin@replaygo.com', 'Admin ReplayGO', 'admin')
-- ) as m(email, full_name, role) on m.email = u.email
-- on conflict (id) do update set
--   name = excluded.name,
--   role = excluded.role,
--   updated_at = now();
-- ============================================================================
