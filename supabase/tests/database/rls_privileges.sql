-- TASK-12 regression checks. Run after migrations with:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/database/rls_privileges.sql

begin;

do $$
declare
  role_name text;
  table_name text;
  privilege_name text;
begin
  foreach role_name in array array['anon', 'authenticated']
  loop
    foreach table_name in array array[
      'public.games',
      'public.game_members',
      'public.game_mvp_votes',
      'public.park_reviews',
      'public.parks_ratings',
      'public.user_sport_stats'
    ]
    loop
      foreach privilege_name in array array['INSERT', 'UPDATE', 'DELETE', 'TRUNCATE']
      loop
        if has_table_privilege(role_name, table_name, privilege_name) then
          raise exception '% unexpectedly has % on %',
            role_name, privilege_name, table_name;
        end if;
      end loop;
    end loop;
  end loop;

  if not has_column_privilege(
    'authenticated', 'public.profiles', 'username', 'UPDATE'
  ) then
    raise exception 'authenticated cannot update safe profile columns';
  end if;

  if has_column_privilege(
    'authenticated', 'public.profiles', 'rating', 'UPDATE'
  ) then
    raise exception 'authenticated can update protected profile statistics';
  end if;
end;
$$;

insert into public.profiles (id, username)
values
  ('00000000-0000-4000-8000-000000000001', 'rls_owner'),
  ('00000000-0000-4000-8000-000000000002', 'rls_other');

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000001',
  true
);

do $$
declare
  affected integer;
  denied boolean := false;
begin
  -- TASK-11 changed these read-only RPCs to SECURITY INVOKER. Prove that the
  -- narrowed table grants still allow their queries to be planned/executed.
  perform * from public.get_games_by_park(
    '00000000-0000-4000-8000-000000000010'
  );
  perform * from public.get_game_details(
    '00000000-0000-4000-8000-000000000010'
  );
  perform * from public.get_user_games();
  perform * from public.get_recent_matches();
  perform public.has_user_rated(
    '00000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-000000000010'
  );

  update public.profiles
  set username = 'rls_owner_updated'
  where id = '00000000-0000-4000-8000-000000000001';
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'owner safe profile update affected % rows', affected;
  end if;

  update public.profiles
  set username = 'rls_hijacked'
  where id = '00000000-0000-4000-8000-000000000002';
  get diagnostics affected = row_count;
  if affected <> 0 then
    raise exception 'owner updated another profile';
  end if;

  begin
    update public.profiles
    set rating = 999999
    where id = '00000000-0000-4000-8000-000000000001';
  exception
    when insufficient_privilege then denied := true;
  end;
  if not denied then
    raise exception 'owner updated protected profile statistics';
  end if;

  denied := false;
  begin
    insert into public.games (
      starts_at, duration_minutes, max_players, creator_id
    ) values (
      now(), 60, 10, '00000000-0000-4000-8000-000000000002'
    );
  exception
    when insufficient_privilege then denied := true;
  end;
  if not denied then
    raise exception 'authenticated user inserted a game directly';
  end if;
end;
$$;

reset role;
set local role anon;

do $$
declare
  denied boolean := false;
begin
  begin
    insert into public.games (starts_at, duration_minutes, max_players)
    values (now(), 60, 10);
  exception
    when insufficient_privilege then denied := true;
  end;

  if not denied then
    raise exception 'anonymous user inserted a game directly';
  end if;
end;
$$;

reset role;
rollback;
