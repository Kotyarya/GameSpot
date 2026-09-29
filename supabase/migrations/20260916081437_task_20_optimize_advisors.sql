-- TASK-20: remove redundant database objects, index the relationships used by
-- the iOS client and RPCs, and make the remaining privileged read RPC enforce
-- ownership explicitly.

-- Both constraints enforce the same (game_id, user_id) uniqueness and each
-- owns an identical backing index. Keep the original canonical constraint.
alter table public.game_members
drop constraint if exists unique_member_per_game;

-- These policies are strict subsets of the remaining policies, so PostgreSQL
-- evaluates them without changing which rows authenticated users can read.
drop policy if exists "Enable users to view their own data only"
on public.profiles;

drop policy if exists "Users can view own profile"
on public.profiles;

drop policy if exists "Enable users to view their own data only"
on public.user_sport_stats;

drop policy if exists "Users can view own sport stats"
on public.user_sport_stats;

-- Core game/member/vote paths and profile-deletion cascades.
create index if not exists game_members_user_id_idx
on public.game_members (user_id);

create index if not exists game_mvp_votes_voter_id_idx
on public.game_mvp_votes (voter_id);

create index if not exists game_mvp_votes_voted_id_idx
on public.game_mvp_votes (voted_id);

create index if not exists games_creator_id_idx
on public.games (creator_id);

create index if not exists games_park_id_starts_at_idx
on public.games (park_id, starts_at);

create index if not exists games_sport_id_idx
on public.games (sport_id);

-- Park detail and rating queries issued by ParkService and rate_park.
create index if not exists park_reviews_park_id_idx
on public.park_reviews (park_id);

create index if not exists parks_hour_park_id_day_of_week_idx
on public.parks_hour (park_id, day_of_week);

create index if not exists parks_images_park_id_is_main_idx
on public.parks_images (park_id, is_main desc);

create index if not exists parks_ratings_park_id_idx
on public.parks_ratings (park_id);

create index if not exists parks_sports_park_id_sport_id_idx
on public.parks_sports (park_id, sport_id);

create index if not exists parks_sports_sport_id_idx
on public.parks_sports (sport_id);

-- Profile and per-sport stat joins used by ProfileService and lifecycle RPCs.
create index if not exists profiles_favorite_sport_id_idx
on public.profiles (favorite_sport_id);

create index if not exists user_sport_stats_user_id_sport_id_idx
on public.user_sport_stats (user_id, sport_id);

create index if not exists user_sport_stats_sport_id_idx
on public.user_sport_stats (sport_id);

-- This RPC must bypass park_reviews RLS because direct table access is denied,
-- but callers may only inspect their own rating state.
create or replace function public.has_user_rated(
  p_user_id uuid,
  p_park_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null
     or p_user_id is distinct from v_user_id then
    raise exception 'Unauthorized'
      using errcode = '42501';
  end if;

  return exists (
    select 1
    from public.park_reviews review
    where review.user_id = v_user_id
      and review.park_id = p_park_id
  );
end;
$$;

revoke execute
on function public.has_user_rated(uuid, uuid)
from public, anon, authenticated, service_role;

grant execute
on function public.has_user_rated(uuid, uuid)
to authenticated;

-- Preserve the rating behavior while removing the unused record variable
-- reported by plpgsql_check. FOUND is set by PERFORM and drives the same
-- insert-or-update branch as the previous SELECT INTO implementation.
create or replace function public.rate_park(
  p_user_id uuid,
  p_park_id uuid,
  p_quality integer,
  p_facilities integer,
  p_activity integer
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  r record;
begin
  if auth.uid() is null or auth.uid() != p_user_id then
    raise exception 'unauthorized';
  end if;

  if p_quality < 1 or p_quality > 5
    or p_facilities < 1 or p_facilities > 5
    or p_activity < 1 or p_activity > 5 then
    raise exception 'invalid rating values';
  end if;

  perform 1
  from public.park_reviews
  where user_id = p_user_id
    and park_id = p_park_id;

  if found then
    update public.park_reviews
    set quality = p_quality,
        facilities = p_facilities,
        activity = p_activity
    where user_id = p_user_id
      and park_id = p_park_id;
  else
    insert into public.park_reviews (
      id,
      user_id,
      park_id,
      quality,
      facilities,
      activity
    ) values (
      gen_random_uuid(),
      p_user_id,
      p_park_id,
      p_quality,
      p_facilities,
      p_activity
    );
  end if;

  select
    avg(quality)::numeric(3,2) as quality_avg,
    avg(facilities)::numeric(3,2) as facilities_avg,
    avg(activity)::numeric(3,2) as activity_avg,
    count(*) as total
  into r
  from public.park_reviews
  where park_id = p_park_id;

  update public.parks_ratings
  set quality_avg = coalesce(r.quality_avg, 0),
      facilities_avg = coalesce(r.facilities_avg, 0),
      activity_avg = coalesce(r.activity_avg, 0),
      overall_avg = (
        coalesce(r.quality_avg, 0)
        + coalesce(r.facilities_avg, 0)
        + coalesce(r.activity_avg, 0)
      ) / 3.0,
      quality_count = r.total,
      facilities_count = r.total,
      activity_count = r.total,
      updated_at = now()
  where park_id = p_park_id;
end;
$$;
