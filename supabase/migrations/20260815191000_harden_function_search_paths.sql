-- TASK-6: pin every application function to trusted schemas so objects created
-- in a caller-controlled schema cannot shadow tables or helper functions.

alter function public.create_game(uuid, uuid, timestamptz)
  set search_path = public, pg_temp;
alter function public.create_user_sport_stats()
  set search_path = public, pg_temp;
alter function public.delete_user_data(uuid)
  set search_path = public, pg_temp;
alter function public.finish_games()
  set search_path = public, pg_temp;
alter function public.get_game_by_id(uuid)
  set search_path = public, pg_temp;
alter function public.get_game_details(uuid)
  set search_path = public, pg_temp;
alter function public.get_games_by_park(uuid)
  set search_path = public, pg_temp;
alter function public.get_recent_matches()
  set search_path = public, pg_temp;
alter function public.get_user_games()
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
