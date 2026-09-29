-- TASK-20 regression checks. Run after migrations with:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
--   -f supabase/tests/database/advisor_hardening.sql

begin;

-- MARK: - Duplicate objects and policy consolidation

do $$
declare
  profile_select_policies integer;
  stats_select_policies integer;
begin
  if exists (
    select 1
    from pg_constraint constraint_info
    where constraint_info.conrelid = 'public.game_members'::regclass
      and constraint_info.conname = 'unique_member_per_game'
  ) then
    raise exception 'duplicate game member constraint still exists';
  end if;

  if not exists (
    select 1
    from pg_constraint constraint_info
    where constraint_info.conrelid = 'public.game_members'::regclass
      and constraint_info.conname = 'unique_game_member'
  ) then
    raise exception 'canonical game member constraint is missing';
  end if;

  select count(*)
  into profile_select_policies
  from pg_policies policy_info
  where policy_info.schemaname = 'public'
    and policy_info.tablename = 'profiles'
    and policy_info.cmd = 'SELECT'
    and 'authenticated' = any(policy_info.roles);

  if profile_select_policies <> 1 then
    raise exception
      'profiles has % authenticated SELECT policies, expected 1',
      profile_select_policies;
  end if;

  select count(*)
  into stats_select_policies
  from pg_policies policy_info
  where policy_info.schemaname = 'public'
    and policy_info.tablename = 'user_sport_stats'
    and policy_info.cmd = 'SELECT'
    and 'authenticated' = any(policy_info.roles);

  if stats_select_policies <> 1 then
    raise exception
      'user_sport_stats has % authenticated SELECT policies, expected 1',
      stats_select_policies;
  end if;
end;
$$;


-- MARK: - Index coverage for release-critical relationships

do $$
declare
  missing_indexes text;
begin
  select string_agg(index_name, ', ' order by index_name)
  into missing_indexes
  from unnest(array[
    'game_members_user_id_idx',
    'game_mvp_votes_voter_id_idx',
    'game_mvp_votes_voted_id_idx',
    'games_creator_id_idx',
    'games_park_id_starts_at_idx',
    'games_sport_id_idx',
    'park_reviews_park_id_idx',
    'parks_hour_park_id_day_of_week_idx',
    'parks_images_park_id_is_main_idx',
    'parks_ratings_park_id_idx',
    'parks_sports_park_id_sport_id_idx',
    'parks_sports_sport_id_idx',
    'profiles_favorite_sport_id_idx',
    'user_sport_stats_user_id_sport_id_idx',
    'user_sport_stats_sport_id_idx'
  ]) as expected(index_name)
  where to_regclass('public.' || index_name) is null;

  if missing_indexes is not null then
    raise exception 'TASK-20 indexes missing: %', missing_indexes;
  end if;
end;
$$;


-- MARK: - Authenticated ownership for privileged rating lookup

do $$
begin
  if has_function_privilege(
    'anon',
    'public.has_user_rated(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception 'anon can execute has_user_rated';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.has_user_rated(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception 'authenticated cannot execute has_user_rated';
  end if;

  if has_function_privilege(
    'service_role',
    'public.has_user_rated(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception 'service_role unexpectedly executes client rating lookup';
  end if;
end;
$$;

insert into public.profiles (id, username)
values
  ('20000000-0000-4000-8000-000000000001', 'advisor_owner'),
  ('20000000-0000-4000-8000-000000000002', 'advisor_other');

insert into public.parks (
  id,
  name,
  latitude,
  longitude,
  address,
  is_active,
  has_lighting
)
values (
  '20000000-0000-4000-8000-000000000010',
  'Advisor Test Park',
  0,
  0,
  'Test address',
  true,
  false
);

insert into public.parks_ratings (park_id)
values ('20000000-0000-4000-8000-000000000010');

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-4000-8000-000000000001',
  true
);

do $$
declare
  has_rating boolean;
  was_denied boolean := false;
begin
  select public.has_user_rated(
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000010'
  )
  into has_rating;

  if has_rating then
    raise exception 'unexpected rating exists for test account';
  end if;

  begin
    perform public.has_user_rated(
      '20000000-0000-4000-8000-000000000002',
      '20000000-0000-4000-8000-000000000010'
    );
  exception
    when insufficient_privilege then
      was_denied := true;
  end;

  if not was_denied then
    raise exception 'authenticated user inspected another user rating state';
  end if;

  perform public.rate_park(
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000010',
    5,
    4,
    3
  );

  perform public.rate_park(
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000010',
    4,
    4,
    4
  );
end;
$$;

reset role;

do $$
declare
  review_count integer;
  overall_rating real;
begin
  select count(*)
  into review_count
  from public.park_reviews review
  where review.user_id = '20000000-0000-4000-8000-000000000001'
    and review.park_id = '20000000-0000-4000-8000-000000000010'
    and review.quality = 4
    and review.facilities = 4
    and review.activity = 4;

  if review_count <> 1 then
    raise exception
      'rate_park insert/update regression produced % matching reviews',
      review_count;
  end if;

  select rating.overall_avg
  into overall_rating
  from public.parks_ratings rating
  where rating.park_id = '20000000-0000-4000-8000-000000000010';

  if overall_rating <> 4 then
    raise exception
      'rate_park aggregate regression produced overall rating %',
      overall_rating;
  end if;
end;
$$;

rollback;
