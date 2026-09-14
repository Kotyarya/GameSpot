-- TASK-58 integration test. Run after migrations with:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/database/account_deletion.sql

begin;

insert into public.sports (
  id,
  name,
  players_per_team,
  duration_minutes,
  minimum_players_for_rewards
)
values (
  '11000000-0000-4000-8000-000000000001',
  'account_deletion_test_sport',
  2,
  60,
  2
);

insert into public.parks (id, name, latitude, longitude, address, is_active)
values (
  '21000000-0000-4000-8000-000000000001',
  'account_deletion_test_park',
  0,
  0,
  'test',
  true
);

insert into public.parks_ratings (
  park_id,
  quality_avg,
  quality_count,
  facilities_avg,
  facilities_count,
  activity_avg,
  activity_count,
  overall_avg
)
values (
  '21000000-0000-4000-8000-000000000001',
  4,
  2,
  4,
  2,
  4,
  2,
  4
);

insert into public.profiles (id, username)
values
  ('31000000-0000-4000-8000-000000000001', 'account_delete_target'),
  ('31000000-0000-4000-8000-000000000002', 'account_delete_survivor');

insert into public.games (
  id,
  park_id,
  creator_id,
  sport_id,
  starts_at,
  duration_minutes,
  max_players
)
values (
  '41000000-0000-4000-8000-000000000001',
  '21000000-0000-4000-8000-000000000001',
  '31000000-0000-4000-8000-000000000001',
  '11000000-0000-4000-8000-000000000001',
  now() + interval '1 hour',
  60,
  4
);

insert into public.game_members (game_id, user_id, team)
values
  (
    '41000000-0000-4000-8000-000000000001',
    '31000000-0000-4000-8000-000000000001',
    'Team Alpha'
  ),
  (
    '41000000-0000-4000-8000-000000000001',
    '31000000-0000-4000-8000-000000000002',
    'Team Beta'
  );

insert into public.game_mvp_votes (game_id, voter_id, voted_id)
values (
  '41000000-0000-4000-8000-000000000001',
  '31000000-0000-4000-8000-000000000002',
  '31000000-0000-4000-8000-000000000001'
);

insert into public.park_reviews (
  id,
  user_id,
  park_id,
  quality,
  facilities,
  activity
)
values
  (
    '51000000-0000-4000-8000-000000000001',
    '31000000-0000-4000-8000-000000000001',
    '21000000-0000-4000-8000-000000000001',
    5,
    5,
    5
  ),
  (
    '51000000-0000-4000-8000-000000000002',
    '31000000-0000-4000-8000-000000000002',
    '21000000-0000-4000-8000-000000000001',
    3,
    3,
    3
  );

set local role authenticated;

do $$
declare
  denied boolean := false;
begin
  begin
    perform public.delete_user_data(
      '31000000-0000-4000-8000-000000000001'
    );
  exception
    when insufficient_privilege then denied := true;
  end;

  if not denied then
    raise exception 'authenticated client executed service-only deletion RPC';
  end if;
end;
$$;

reset role;
set local role service_role;

select public.delete_user_data(
  '31000000-0000-4000-8000-000000000001'
);

-- A retry after a partial Edge Function failure must remain safe.
select public.delete_user_data(
  '31000000-0000-4000-8000-000000000001'
);

reset role;

-- Make the preserved game visible in Recent Matches.
update public.games
set
  starts_at = now() - interval '1 hour',
  is_finished = true
where id = '41000000-0000-4000-8000-000000000001';

-- Read the preserved game as the surviving participant.
set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '31000000-0000-4000-8000-000000000002',
  true
);

do $$
declare
  result_count integer;
begin
  -- Park Details must return the game with a nullable creator.
  select count(*)
  into result_count
  from public.get_games_by_park(
    '21000000-0000-4000-8000-000000000001'
  )
  where id = '41000000-0000-4000-8000-000000000001'
    and creator_id is null
    and joined_players = 1;

  if result_count <> 1 then
    raise exception
      'get_games_by_park did not return the preserved creatorless game';
  end if;

  -- My Games must return it to the remaining participant.
  select count(*)
  into result_count
  from public.get_user_games()
  where id = '41000000-0000-4000-8000-000000000001'
    and creator_id is null
    and joined_players = 1;

  if result_count <> 1 then
    raise exception
      'get_user_games did not return the preserved creatorless game';
  end if;

  -- Game Details must still open.
  select count(*)
  into result_count
  from public.get_game_details(
    '41000000-0000-4000-8000-000000000001'
  )
  where id = '41000000-0000-4000-8000-000000000001'
    and is_joined = true
    and joined_players = 1;

  if result_count <> 1 then
    raise exception
      'get_game_details did not return the preserved game';
  end if;

  -- The finished game must remain in Recent Matches.
  select count(*)
  into result_count
  from public.get_recent_matches()
  where id = '41000000-0000-4000-8000-000000000001';

  if result_count <> 1 then
    raise exception
      'get_recent_matches did not return the preserved game';
  end if;
end;
$$;

reset role;

do $$
begin
  if exists (
    select 1
    from public.profiles
    where id = '31000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'profile was not deleted';
  end if;

  if exists (
    select 1
    from public.game_members
    where user_id = '31000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'game membership was not deleted';
  end if;

  if exists (
    select 1
    from public.game_mvp_votes
    where voter_id = '31000000-0000-4000-8000-000000000001'
       or voted_id = '31000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'MVP votes were not deleted';
  end if;

  if exists (
    select 1
    from public.park_reviews
    where user_id = '31000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'park review was not deleted';
  end if;

  if exists (
    select 1
    from public.user_sport_stats
    where user_id = '31000000-0000-4000-8000-000000000001'
  ) then
    raise exception 'sport stats were not deleted';
  end if;

  if not exists (
    select 1
    from public.games
    where id = '41000000-0000-4000-8000-000000000001'
      and creator_id is null
  ) then
    raise exception 'shared match history was not anonymized';
  end if;

  if not exists (
    select 1
    from public.profiles
    where id = '31000000-0000-4000-8000-000000000002'
  ) then
    raise exception 'another user was deleted';
  end if;

  if not exists (
    select 1
    from public.parks_ratings
    where park_id = '21000000-0000-4000-8000-000000000001'
      and quality_avg = 3
      and facilities_avg = 3
      and activity_avg = 3
      and overall_avg = 3
      and quality_count = 1
      and facilities_count = 1
      and activity_count = 1
  ) then
    raise exception 'park aggregate was not recalculated';
  end if;
end;
$$;

rollback;
