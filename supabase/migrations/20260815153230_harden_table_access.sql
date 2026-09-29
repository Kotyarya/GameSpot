-- TASK-12: make the Data API read-mostly and route business mutations through
-- the authenticated RPCs hardened in TASK-11.

revoke all privileges on table
  public.game_members,
  public.game_mvp_votes,
  public.games,
  public.park_reviews,
  public.parks,
  public.parks_hour,
  public.parks_images,
  public.parks_ratings,
  public.parks_sports,
  public.profiles,
  public.sports,
  public.user_sport_stats
from anon, authenticated;

revoke usage on sequence
  public.game_mvp_votes_id_seq,
  public.parks_hour_id_seq,
  public.parks_images_id_seq,
  public.parks_ratings_id_seq,
  public.parks_sports_id_seq
from anon, authenticated;

-- A signed-out client may only load the static public venue catalogue.
grant select on table
  public.parks,
  public.parks_hour,
  public.parks_images,
  public.parks_ratings,
  public.parks_sports,
  public.sports
to anon;

-- Signed-in users need these reads for the map, games, profile and Realtime.
grant select on table
  public.game_members,
  public.game_mvp_votes,
  public.games,
  public.parks,
  public.parks_hour,
  public.parks_images,
  public.parks_ratings,
  public.parks_sports,
  public.profiles,
  public.sports,
  public.user_sport_stats
to authenticated;

-- RLS controls the row; column privileges prevent profile/stat escalation.
grant update (
  username,
  avatar_url,
  favorite_sport_id,
  is_onboarded,
  is_profile_completed
)
on table public.profiles
to authenticated;

-- Remove both the production policy names and the baseline aliases so this
-- migration is safe on the existing project and on a clean local reset.
drop policy if exists "Enable insert for authenticated users only"
  on public.games;
drop policy if exists "Authenticated users can create games"
  on public.games;
drop policy if exists "Enable read access for all users"
  on public.games;
drop policy if exists "Games are viewable by everyone"
  on public.games;
create policy "Authenticated users can read games"
on public.games
for select
to authenticated
using (true);

drop policy if exists "Enable insert for authenticated users only"
  on public.game_members;
drop policy if exists "Authenticated users can join games"
  on public.game_members;
drop policy if exists "Enable read access for all users"
  on public.game_members;
drop policy if exists "Game members are viewable by everyone"
  on public.game_members;
create policy "Authenticated users can read game members"
on public.game_members
for select
to authenticated
using (true);

drop policy if exists "Enable insert for authenticated users only"
  on public.game_mvp_votes;
drop policy if exists "Authenticated users can vote"
  on public.game_mvp_votes;
drop policy if exists "Enable read access for all users"
  on public.game_mvp_votes;
drop policy if exists "MVP votes are viewable by everyone"
  on public.game_mvp_votes;
create policy "Authenticated users can read MVP votes"
on public.game_mvp_votes
for select
to authenticated
using (true);

drop policy if exists "Enable insert for authenticated users only"
  on public.park_reviews;
drop policy if exists "Authenticated users can create park reviews"
  on public.park_reviews;
drop policy if exists "Enable read access for all users"
  on public.park_reviews;
drop policy if exists "Park reviews are viewable by everyone"
  on public.park_reviews;
drop policy if exists "Policy with table joins"
  on public.park_reviews;
drop policy if exists "Park reviews are updateable by everyone"
  on public.park_reviews;

drop policy if exists "Enable insert for authenticated users only"
  on public.parks_ratings;
drop policy if exists "Authenticated users can create park ratings"
  on public.parks_ratings;
drop policy if exists "Allow update ratings for auth users"
  on public.parks_ratings;
drop policy if exists "Authenticated users can update park ratings"
  on public.parks_ratings;

drop policy if exists "Users can update own profile"
  on public.profiles;
drop policy if exists "Users can upload own profile"
  on public.profiles;
create policy "Users can update own safe profile fields"
on public.profiles
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
);
