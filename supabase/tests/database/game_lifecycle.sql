-- TASK-13 integration test. Run after migrations with:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/database/game_lifecycle.sql

begin;

insert into public.sports (
  id,
  name,
  players_per_team,
  duration_minutes,
  minimum_players_for_rewards
)
values (
  '10000000-0000-4000-8000-000000000001',
  'lifecycle_test_sport',
  2,
  60,
  3
);

insert into public.parks (id, name, latitude, longitude, address, is_active)
values (
  '20000000-0000-4000-8000-000000000001',
  'lifecycle_test_park',
  0,
  0,
  'test',
  true
);

insert into public.parks_sports (park_id, sport_id)
values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001'
);

insert into public.profiles (id, username)
values
  ('30000000-0000-4000-8000-000000000001', 'lifecycle_owner'),
  ('30000000-0000-4000-8000-000000000002', 'lifecycle_player_2'),
  ('30000000-0000-4000-8000-000000000003', 'lifecycle_player_3'),
  ('30000000-0000-4000-8000-000000000004', 'lifecycle_outsider');

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000001',
  true
);

do $$
declare
  denied boolean := false;
begin
  begin
    perform public.create_game(
      '20000000-0000-4000-8000-000000000001',
      '10000000-0000-4000-8000-000000000001',
      now() - interval '1 minute'
    );
  exception
    when raise_exception then denied := true;
  end;

  if not denied then
    raise exception 'a game was created in the past';
  end if;
end;
$$;

select set_config(
  'gamespot.test_game_id',
  public.create_game(
    '20000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000001',
    now() + interval '1 hour'
  )::text,
  true
);

reset role;

do $$
begin
  if exists (
    select 1
    from public.profiles
    where id = '30000000-0000-4000-8000-000000000001'
      and (rating <> 0 or games_played <> 0 or perf_points <> 0)
  ) then
    raise exception 'creating a game granted participation rewards';
  end if;
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000002',
  true
);
select public.join_game(
  current_setting('gamespot.test_game_id')::uuid,
  'Team Alpha'
);

select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000003',
  true
);
select public.join_game(
  current_setting('gamespot.test_game_id')::uuid,
  'Team Beta'
);
reset role;

update public.games
set starts_at = now() - interval '60 minutes 30 seconds'
where id = current_setting('gamespot.test_game_id')::uuid;

select public.finish_games();

do $$
begin
  if not exists (
    select 1
    from public.games
    where id = current_setting('gamespot.test_game_id')::uuid
      and is_in_progress = false
      and is_finished = false
  ) then
    raise exception 'scheduled game skipped the in-progress state';
  end if;
end;
$$;

select public.start_games();

do $$
begin
  if not exists (
    select 1
    from public.games
    where id = current_setting('gamespot.test_game_id')::uuid
      and is_in_progress = true
      and is_finished = false
      and mvp_voting_open = false
      and is_processed = false
  ) then
    raise exception 'scheduled game did not enter in-progress state';
  end if;
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000004',
  true
);

do $$
declare
  denied boolean := false;
begin
  begin
    perform public.join_game(
      current_setting('gamespot.test_game_id')::uuid,
      'Team Beta'
    );
  exception
    when raise_exception then denied := true;
  end;
  if not denied then
    raise exception 'outsider joined after the game started';
  end if;
end;
$$;

select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000001',
  true
);

do $$
declare
  leave_denied boolean := false;
  vote_denied boolean := false;
begin
  begin
    perform public.leave_game(
      current_setting('gamespot.test_game_id')::uuid
    );
  exception
    when raise_exception then leave_denied := true;
  end;
  if not leave_denied then
    raise exception 'participant left after the game started';
  end if;

  begin
    perform public.vote_mvp(
      current_setting('gamespot.test_game_id')::uuid,
      '30000000-0000-4000-8000-000000000002'
    );
  exception
    when raise_exception then vote_denied := true;
  end;
  if not vote_denied then
    raise exception 'participant voted before the game finished';
  end if;
end;
$$;

reset role;

select public.finish_games();

do $$
begin
  if not exists (
    select 1
    from public.games
    where id = current_setting('gamespot.test_game_id')::uuid
      and is_in_progress = false
      and is_finished = true
      and mvp_voting_open = false
      and is_processed = false
      and participation_rewards_given = false
  ) then
    raise exception 'in-progress game did not enter finished state';
  end if;
end;
$$;

select public.open_mvp_voting();

do $$
declare
  points_before bigint;
  points_after bigint;
begin
  if not exists (
    select 1
    from public.games
    where id = current_setting('gamespot.test_game_id')::uuid
      and is_finished = true
      and mvp_voting_open = true
      and is_processed = false
      and participation_rewards_given = true
  ) then
    raise exception 'finished game did not enter voting state';
  end if;

  if (
    select count(*)
    from public.profiles
    where id in (
      '30000000-0000-4000-8000-000000000001',
      '30000000-0000-4000-8000-000000000002',
      '30000000-0000-4000-8000-000000000003'
    )
      and games_played = 1
  ) <> 3 then
    raise exception 'participation rewards were not granted once to all players';
  end if;

  select perf_points into points_before
  from public.profiles
  where id = '30000000-0000-4000-8000-000000000001';

  perform public.open_mvp_voting();

  select perf_points into points_after
  from public.profiles
  where id = '30000000-0000-4000-8000-000000000001';

  if points_after <> points_before then
    raise exception 'participation rewards were granted more than once';
  end if;
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000001',
  true
);
select public.vote_mvp(
  current_setting('gamespot.test_game_id')::uuid,
  '30000000-0000-4000-8000-000000000002'
);

do $$
declare
  denied boolean := false;
begin
  begin
    perform public.vote_mvp(
      current_setting('gamespot.test_game_id')::uuid,
      '30000000-0000-4000-8000-000000000003'
    );
  exception
    when raise_exception then denied := true;
  end;
  if not denied then
    raise exception 'participant voted more than once';
  end if;
end;
$$;

select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000002',
  true
);
select public.vote_mvp(
  current_setting('gamespot.test_game_id')::uuid,
  '30000000-0000-4000-8000-000000000001'
);

select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000003',
  true
);
select public.vote_mvp(
  current_setting('gamespot.test_game_id')::uuid,
  '30000000-0000-4000-8000-000000000001'
);

select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-4000-8000-000000000004',
  true
);

do $$
declare
  denied boolean := false;
begin
  begin
    perform public.vote_mvp(
      current_setting('gamespot.test_game_id')::uuid,
      '30000000-0000-4000-8000-000000000001'
    );
  exception
    when raise_exception then denied := true;
  end;
  if not denied then
    raise exception 'non-participant cast an MVP vote';
  end if;
end;
$$;

reset role;

update public.games
set starts_at = now() - interval '64 minutes'
where id = current_setting('gamespot.test_game_id')::uuid;

select public.process_finished_games();

do $$
declare
  winner_rating bigint;
  winner_points bigint;
  winner_mvp_count bigint;
begin
  if not exists (
    select 1
    from public.games
    where id = current_setting('gamespot.test_game_id')::uuid
      and is_finished = true
      and is_in_progress = false
      and mvp_voting_open = false
      and is_processed = true
  ) then
    raise exception 'voting game did not enter processed state';
  end if;

  if not exists (
    select 1
    from public.game_members
    where game_id = current_setting('gamespot.test_game_id')::uuid
      and user_id = '30000000-0000-4000-8000-000000000001'
      and was_mvp = true
  ) then
    raise exception 'deterministic MVP winner was not stored';
  end if;

  select rating, perf_points, mvp_count
  into winner_rating, winner_points, winner_mvp_count
  from public.profiles
  where id = '30000000-0000-4000-8000-000000000001';

  perform public.process_finished_games();

  if not exists (
    select 1
    from public.profiles
    where id = '30000000-0000-4000-8000-000000000001'
      and rating = winner_rating
      and perf_points = winner_points
      and mvp_count = winner_mvp_count
      and mvp_count = 1
  ) then
    raise exception 'MVP rewards were granted more than once';
  end if;
end;
$$;

rollback;
