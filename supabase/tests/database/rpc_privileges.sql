-- TASK-11 regression checks. Run after migrations with:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/database/rpc_privileges.sql

begin;

do $$
declare
  signature text;
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    if has_function_privilege(
      'anon', 'public.rls_auto_enable()', 'EXECUTE'
    ) or has_function_privilege(
      'authenticated', 'public.rls_auto_enable()', 'EXECUTE'
    ) then
      raise exception 'client role can execute platform RLS event trigger';
    end if;
  end if;

  foreach signature in array array[
    'public.create_game(uuid,uuid,timestamp with time zone)',
    'public.finish_games()',
    'public.has_user_rated(uuid,uuid)',
    'public.join_game(uuid,public.teams)',
    'public.leave_game(uuid)',
    'public.open_mvp_voting()',
    'public.process_finished_games()',
    'public.rate_park(uuid,uuid,integer,integer,integer)',
    'public.start_games()',
    'public.vote_mvp(uuid,uuid)'
  ]
  loop
    if has_function_privilege('anon', signature, 'EXECUTE') then
      raise exception 'anon unexpectedly has EXECUTE on %', signature;
    end if;
  end loop;
end;
$$;

set local role anon;

do $$
declare
  denied boolean := false;
begin
  begin
    perform public.start_games();
  exception
    when insufficient_privilege then denied := true;
  end;

  if not denied then
    raise exception 'anonymous lifecycle RPC call unexpectedly succeeded';
  end if;
end;
$$;

reset role;

do $$
declare
  signature text;
begin
  foreach signature in array array[
    'public.create_game(uuid,uuid,timestamp with time zone)',
    'public.get_game_details(uuid)',
    'public.get_games_by_park(uuid)',
    'public.get_recent_matches()',
    'public.get_user_games()',
    'public.has_user_rated(uuid,uuid)',
    'public.join_game(uuid,public.teams)',
    'public.leave_game(uuid)',
    'public.rate_park(uuid,uuid,integer,integer,integer)',
    'public.vote_mvp(uuid,uuid)'
  ]
  loop
    if not has_function_privilege('authenticated', signature, 'EXECUTE') then
      raise exception 'authenticated is missing EXECUTE on %', signature;
    end if;
  end loop;

  foreach signature in array array[
    'public.finish_games()',
    'public.open_mvp_voting()',
    'public.process_finished_games()',
    'public.start_games()'
  ]
  loop
    if has_function_privilege('authenticated', signature, 'EXECUTE') then
      raise exception 'authenticated unexpectedly has EXECUTE on %', signature;
    end if;
    if not has_function_privilege('service_role', signature, 'EXECUTE') then
      raise exception 'service_role is missing EXECUTE on %', signature;
    end if;
  end loop;
end;
$$;

rollback;
