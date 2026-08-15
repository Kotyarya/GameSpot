-- TASK-13: deterministic GameSpot match lifecycle.
--
-- scheduled -> in progress -> finished + voting -> processed
--                                  \-> processed (not enough participants)

create or replace function public.create_game(
  p_park_id uuid,
  p_sport_id uuid,
  p_starts_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_players_per_team integer;
  v_duration_minutes integer;
  v_game_id uuid;
begin
  if v_user_id is null then
    raise exception 'Unauthorized';
  end if;

  if p_starts_at <= now() then
    raise exception 'Game must start in the future';
  end if;

  if not exists (
    select 1
    from public.parks_sports ps
    where ps.park_id = p_park_id
      and ps.sport_id = p_sport_id
  ) then
    raise exception 'Sport not available in this park';
  end if;

  select s.players_per_team, s.duration_minutes
  into v_players_per_team, v_duration_minutes
  from public.sports s
  where s.id = p_sport_id;

  if not found then
    raise exception 'Sport not found';
  end if;

  if exists (
    select 1
    from public.games g
    where g.park_id = p_park_id
      and g.is_finished = false
      and p_starts_at < g.starts_at + make_interval(mins => g.duration_minutes)
      and p_starts_at + make_interval(mins => v_duration_minutes) > g.starts_at
  ) then
    raise exception 'Another game already exists during this time';
  end if;

  insert into public.games (
    park_id,
    creator_id,
    sport_id,
    starts_at,
    duration_minutes,
    max_players
  ) values (
    p_park_id,
    v_user_id,
    p_sport_id,
    p_starts_at,
    v_duration_minutes,
    v_players_per_team * 2
  )
  returning id into v_game_id;

  insert into public.game_members (game_id, user_id, team, was_mvp)
  values (v_game_id, v_user_id, 'Team Alpha', false);

  return v_game_id;
end;
$$;

create or replace function public.join_game(
  p_game_id uuid,
  p_team public.teams
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_max_players integer;
  v_starts_at timestamptz;
  v_is_in_progress boolean;
  v_is_finished boolean;
  v_is_processed boolean;
  v_mvp_voting_open boolean;
  v_team_count integer;
begin
  if v_user_id is null then
    raise exception 'Unauthorized';
  end if;

  select
    g.max_players,
    g.starts_at,
    g.is_in_progress,
    g.is_finished,
    g.is_processed,
    g.mvp_voting_open
  into
    v_max_players,
    v_starts_at,
    v_is_in_progress,
    v_is_finished,
    v_is_processed,
    v_mvp_voting_open
  from public.games g
  where g.id = p_game_id
  for update;

  if not found then
    raise exception 'Game not found';
  end if;

  if v_starts_at <= now()
    or v_is_in_progress
    or v_is_finished
    or v_is_processed
    or v_mvp_voting_open then
    raise exception 'Game has already started';
  end if;

  if exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = v_user_id
  ) then
    raise exception 'User already joined';
  end if;

  select count(*) into v_team_count
  from public.game_members gm
  where gm.game_id = p_game_id
    and gm.team = p_team;

  if v_team_count >= v_max_players / 2 then
    raise exception 'Team is full';
  end if;

  insert into public.game_members (game_id, user_id, team)
  values (p_game_id, v_user_id, p_team);
end;
$$;

create or replace function public.leave_game(p_game_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_starts_at timestamptz;
  v_is_in_progress boolean;
  v_is_finished boolean;
  v_is_processed boolean;
  v_mvp_voting_open boolean;
begin
  if v_user_id is null then
    raise exception 'Unauthorized';
  end if;

  select
    g.starts_at,
    g.is_in_progress,
    g.is_finished,
    g.is_processed,
    g.mvp_voting_open
  into
    v_starts_at,
    v_is_in_progress,
    v_is_finished,
    v_is_processed,
    v_mvp_voting_open
  from public.games g
  where g.id = p_game_id
  for update;

  if not found then
    raise exception 'Game not found';
  end if;

  if v_starts_at <= now()
    or v_is_in_progress
    or v_is_finished
    or v_is_processed
    or v_mvp_voting_open then
    raise exception 'Cannot leave after the game has started';
  end if;

  delete from public.game_members gm
  where gm.game_id = p_game_id
    and gm.user_id = v_user_id;

  if not found then
    raise exception 'User is not a participant';
  end if;
end;
$$;

create or replace function public.start_games()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.games
  set is_in_progress = true
  where starts_at <= now()
    and is_in_progress = false
    and is_finished = false
    and is_processed = false
    and mvp_voting_open = false;
end;
$$;

create or replace function public.finish_games()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.games
  set is_in_progress = false,
      is_finished = true,
      mvp_voting_open = false
  where is_finished = false
    and is_in_progress = true
    and is_processed = false
    and starts_at + make_interval(mins => duration_minutes) <= now();
end;
$$;

create or replace function public.open_mvp_voting()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_game record;
  v_participant_count integer;
begin
  for v_game in
    select g.id, g.sport_id, s.minimum_players_for_rewards
    from public.games g
    join public.sports s on s.id = g.sport_id
    where g.is_finished = true
      and g.is_in_progress = false
      and g.is_processed = false
      and g.mvp_voting_open = false
      and g.participation_rewards_given = false
      and g.starts_at + make_interval(mins => g.duration_minutes) <= now()
    order by g.starts_at, g.id
    for update of g skip locked
  loop
    select count(*) into v_participant_count
    from public.game_members gm
    where gm.game_id = v_game.id;

    if v_participant_count < v_game.minimum_players_for_rewards then
      update public.games
      set is_processed = true,
          participation_rewards_given = true
      where id = v_game.id;
      continue;
    end if;

    update public.profiles p
    set rating = p.rating + 10,
        games_played = p.games_played + 1,
        perf_points = p.perf_points + 35
    where p.id in (
      select gm.user_id
      from public.game_members gm
      where gm.game_id = v_game.id
    );

    update public.user_sport_stats uss
    set rating = uss.rating + 15,
        games_played = uss.games_played + 1,
        perf_points = uss.perf_points + 40
    where uss.sport_id = v_game.sport_id
      and uss.user_id in (
        select gm.user_id
        from public.game_members gm
        where gm.game_id = v_game.id
      );

    update public.game_members
    set rating_change = 15,
        perf_points_earned = 40
    where game_id = v_game.id;

    update public.games
    set mvp_voting_open = true,
        participation_rewards_given = true
    where id = v_game.id;
  end loop;
end;
$$;

create or replace function public.vote_mvp(
  p_game_id uuid,
  p_voted_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_is_finished boolean;
  v_is_processed boolean;
  v_voting_open boolean;
  v_voting_deadline timestamptz;
begin
  if v_user_id is null then
    raise exception 'Unauthorized';
  end if;

  if v_user_id = p_voted_user_id then
    raise exception 'You cannot vote for yourself';
  end if;

  select
    g.is_finished,
    g.is_processed,
    g.mvp_voting_open,
    g.starts_at + make_interval(mins => g.duration_minutes + 3)
  into
    v_is_finished,
    v_is_processed,
    v_voting_open,
    v_voting_deadline
  from public.games g
  where g.id = p_game_id
  for update;

  if not found then
    raise exception 'Game not found';
  end if;

  if not v_is_finished or v_is_processed or not v_voting_open then
    raise exception 'MVP voting is closed';
  end if;

  if now() >= v_voting_deadline then
    raise exception 'MVP voting window has ended';
  end if;

  if not exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = v_user_id
  ) then
    raise exception 'You are not a participant';
  end if;

  if not exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = p_voted_user_id
  ) then
    raise exception 'Player is not in this game';
  end if;

  insert into public.game_mvp_votes (game_id, voter_id, voted_id)
  values (p_game_id, v_user_id, p_voted_user_id);

  update public.profiles
  set perf_points = perf_points + 2
  where id = v_user_id;
exception
  when unique_violation then
    raise exception 'You already voted';
end;
$$;

create or replace function public.process_finished_games()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_game record;
  v_mvp_user_id uuid;
  v_votes_count integer;
begin
  for v_game in
    select g.id, g.sport_id
    from public.games g
    where g.is_finished = true
      and g.is_processed = false
      and g.mvp_voting_open = true
      and g.starts_at + make_interval(mins => g.duration_minutes + 3) <= now()
    order by g.starts_at, g.id
    for update skip locked
  loop
    v_mvp_user_id := null;
    v_votes_count := 0;

    select gmv.voted_id, count(*)::integer
    into v_mvp_user_id, v_votes_count
    from public.game_mvp_votes gmv
    where gmv.game_id = v_game.id
    group by gmv.voted_id
    order by count(*) desc, gmv.voted_id
    limit 1;

    if v_mvp_user_id is not null then
      update public.profiles
      set rating = rating + 25 + (v_votes_count * 3),
          perf_points = perf_points + 70 + (v_votes_count * 8),
          mvp_count = mvp_count + 1
      where id = v_mvp_user_id;

      update public.user_sport_stats
      set rating = rating + 35 + (v_votes_count * 5),
          perf_points = perf_points + 80 + (v_votes_count * 10),
          mvp_count = mvp_count + 1
      where user_id = v_mvp_user_id
        and sport_id = v_game.sport_id;

      update public.game_members
      set was_mvp = true,
          rating_change = rating_change + 35 + (v_votes_count * 5),
          perf_points_earned = perf_points_earned + 80 + (v_votes_count * 10)
      where game_id = v_game.id
        and user_id = v_mvp_user_id;
    end if;

    update public.games
    set is_in_progress = false,
        mvp_voting_open = false,
        is_processed = true
    where id = v_game.id;
  end loop;
end;
$$;
