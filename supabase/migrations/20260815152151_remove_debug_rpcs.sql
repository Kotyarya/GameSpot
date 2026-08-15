-- Debug RPCs are not used by the iOS application. In production they bypass
-- authorization and contain hard-coded user identifiers, so they must not be
-- part of an App Store backend.
drop function if exists public.debug_add_test_votes(uuid);
drop function if exists public.debug_join_test_players(uuid);
drop function if exists public.debug_set_game_started(uuid);
