-- TASK-11: expose only the RPC surface required by the signed-in iOS client.

-- Prevent new functions from being exposed automatically. Every future RPC
-- must receive an explicit grant in the same migration that creates it.
alter default privileges in schema public
revoke execute on functions from public, anon, authenticated, service_role;

revoke execute on function
  public.create_game(uuid, uuid, timestamptz),
  public.create_user_sport_stats(),
  public.finish_games(),
  public.get_game_by_id(uuid),
  public.get_game_details(uuid),
  public.get_games_by_park(uuid),
  public.get_recent_matches(),
  public.get_user_games(),
  public.handle_new_user(),
  public.has_user_rated(uuid, uuid),
  public.join_game(uuid, public.teams),
  public.leave_game(uuid),
  public.open_mvp_voting(),
  public.process_finished_games(),
  public.rate_park(uuid, uuid, integer, integer, integer),
  public.start_games(),
  public.vote_mvp(uuid, uuid)
from public, anon, authenticated, service_role;

-- These read-only functions can respect the caller's RLS and table grants.
alter function public.get_game_by_id(uuid) security invoker;
alter function public.get_game_details(uuid) security invoker;
alter function public.get_games_by_park(uuid) security invoker;
alter function public.get_recent_matches() security invoker;
alter function public.get_user_games() security invoker;

-- A fixed path prevents temporary objects from shadowing trusted objects.
-- Client roles have USAGE but not CREATE on the public schema.
alter function public.create_game(uuid, uuid, timestamptz)
  set search_path = public, pg_temp;
alter function public.finish_games()
  set search_path = public, pg_temp;
alter function public.handle_new_user()
  set search_path = public, pg_temp;
alter function public.has_user_rated(uuid, uuid)
  set search_path = public, pg_temp;
alter function public.join_game(uuid, public.teams)
  set search_path = public, pg_temp;
alter function public.leave_game(uuid)
  set search_path = public, pg_temp;
alter function public.open_mvp_voting()
  set search_path = public, pg_temp;
alter function public.process_finished_games()
  set search_path = public, pg_temp;
alter function public.rate_park(uuid, uuid, integer, integer, integer)
  set search_path = public, pg_temp;
alter function public.start_games()
  set search_path = public, pg_temp;
alter function public.vote_mvp(uuid, uuid)
  set search_path = public, pg_temp;

-- The application is authenticated before it reaches any of these flows.
grant execute on function
  public.create_game(uuid, uuid, timestamptz),
  public.get_game_details(uuid),
  public.get_games_by_park(uuid),
  public.get_recent_matches(),
  public.get_user_games(),
  public.has_user_rated(uuid, uuid),
  public.join_game(uuid, public.teams),
  public.leave_game(uuid),
  public.rate_park(uuid, uuid, integer, integer, integer),
  public.vote_mvp(uuid, uuid)
to authenticated, service_role;

-- Scheduled jobs are not part of the public Data API contract.
grant execute on function
  public.finish_games(),
  public.open_mvp_voting(),
  public.process_finished_games(),
  public.start_games()
to service_role;
