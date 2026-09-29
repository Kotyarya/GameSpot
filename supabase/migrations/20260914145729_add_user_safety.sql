-- TASK-78: minimal reporting, blocking, and username moderation for App Review.

-- MARK: - Reports

create table public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null
    references public.profiles (id) on delete cascade,
  reported_user_id uuid not null
    references public.profiles (id) on delete cascade,
  reported_username text not null,
  reported_avatar_url text,
  reason text not null,
  details text,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint user_reports_no_self_report
    check (reporter_id <> reported_user_id),

  constraint user_reports_reason_check
    check (
      reason in (
        'offensive_username',
        'offensive_avatar',
        'abusive_behavior',
        'other'
      )
    ),

  constraint user_reports_details_length_check
    check (
      details is null
      or char_length(details) <= 500
    ),

  constraint user_reports_status_check
    check (
      status in (
        'pending',
        'reviewed',
        'dismissed',
        'actioned'
      )
    ),

  constraint user_reports_unique_reason
    unique (reporter_id, reported_user_id, reason)
);

create index user_reports_reported_user_id_idx
on public.user_reports (reported_user_id);

alter table public.user_reports enable row level security;

create policy "Users can read own submitted reports"
on public.user_reports
for select
to authenticated
using (
  (select auth.uid()) = reporter_id
);

revoke all privileges
on table public.user_reports
from public, anon, authenticated, service_role;

grant select
on table public.user_reports
to authenticated;

grant select, update
on table public.user_reports
to service_role;

create or replace function public.touch_user_report_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute
on function public.touch_user_report_updated_at()
from public, anon, authenticated, service_role;

create trigger touch_user_report_updated_at
before update
on public.user_reports
for each row
execute function public.touch_user_report_updated_at();


-- MARK: - Blocks

create table public.user_blocks (
  blocker_id uuid not null
    references public.profiles (id) on delete cascade,
  blocked_id uuid not null
    references public.profiles (id) on delete cascade,
  blocked_username text not null,
  blocked_avatar_url text,
  created_at timestamptz not null default now(),

  constraint user_blocks_pkey
    primary key (blocker_id, blocked_id),

  constraint user_blocks_no_self_block
    check (blocker_id <> blocked_id)
);

create index user_blocks_blocked_id_idx
on public.user_blocks (blocked_id);

alter table public.user_blocks enable row level security;

create policy "Users can read own blocks"
on public.user_blocks
for select
to authenticated
using (
  (select auth.uid()) = blocker_id
);

revoke all privileges
on table public.user_blocks
from public, anon, authenticated, service_role;

grant select
on table public.user_blocks
to authenticated;

grant select
on table public.user_blocks
to service_role;


-- MARK: - Submit report RPC

create or replace function public.submit_user_report(
  p_reported_user_id uuid,
  p_reason text,
  p_details text default null
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_reporter_id uuid := auth.uid();
  v_reason text := lower(trim(coalesce(p_reason, '')));
  v_details text := nullif(trim(coalesce(p_details, '')), '');
  v_username text;
  v_avatar_url text;
  v_report_id uuid;
begin
  if v_reporter_id is null then
    raise exception 'Authentication required'
      using errcode = '42501';
  end if;

  if p_reported_user_id is null then
    raise exception 'Reported user is required'
      using errcode = '22023';
  end if;

  if p_reported_user_id = v_reporter_id then
    raise exception 'You cannot report yourself'
      using errcode = '22023';
  end if;

  if v_reason not in (
    'offensive_username',
    'offensive_avatar',
    'abusive_behavior',
    'other'
  ) then
    raise exception 'Invalid report reason'
      using errcode = '22023';
  end if;

  if v_details is not null
     and char_length(v_details) > 500 then
    raise exception 'Report details are too long'
      using errcode = '22023';
  end if;

  select
    profile.username,
    profile.avatar_url
  into
    v_username,
    v_avatar_url
  from public.profiles profile
  where profile.id = p_reported_user_id;

  if not found then
    raise exception 'Reported user does not exist'
      using errcode = '22023';
  end if;

  insert into public.user_reports (
    reporter_id,
    reported_user_id,
    reported_username,
    reported_avatar_url,
    reason,
    details
  )
  values (
    v_reporter_id,
    p_reported_user_id,
    coalesce(v_username, 'Unknown user'),
    v_avatar_url,
    v_reason,
    v_details
  )
  on conflict (
    reporter_id,
    reported_user_id,
    reason
  )
  do nothing
  returning id into v_report_id;

  return v_report_id is not null;
end;
$$;

revoke execute
on function public.submit_user_report(uuid, text, text)
from public, anon, authenticated, service_role;

grant execute
on function public.submit_user_report(uuid, text, text)
to authenticated;


-- MARK: - Block/unblock RPC

create or replace function public.set_user_block(
  p_blocked_user_id uuid,
  p_is_blocked boolean
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_blocker_id uuid := auth.uid();
  v_username text;
  v_avatar_url text;
begin
  if v_blocker_id is null then
    raise exception 'Authentication required'
      using errcode = '42501';
  end if;

  if p_blocked_user_id is null then
    raise exception 'Blocked user is required'
      using errcode = '22023';
  end if;

  if p_is_blocked is null then
    raise exception 'Block state is required'
      using errcode = '22023';
  end if;

  if p_blocked_user_id = v_blocker_id then
    raise exception 'You cannot block yourself'
      using errcode = '22023';
  end if;

  if p_is_blocked then
    select
      profile.username,
      profile.avatar_url
    into
      v_username,
      v_avatar_url
    from public.profiles profile
    where profile.id = p_blocked_user_id;

    if not found then
      raise exception 'Blocked user does not exist'
        using errcode = '22023';
    end if;

    insert into public.user_blocks (
      blocker_id,
      blocked_id,
      blocked_username,
      blocked_avatar_url
    )
    values (
      v_blocker_id,
      p_blocked_user_id,
      coalesce(v_username, 'Unknown user'),
      v_avatar_url
    )
    on conflict (blocker_id, blocked_id)
    do update set
      blocked_username = excluded.blocked_username,
      blocked_avatar_url = excluded.blocked_avatar_url;

  else
    delete from public.user_blocks
    where blocker_id = v_blocker_id
      and blocked_id = p_blocked_user_id;
  end if;
end;
$$;

revoke execute
on function public.set_user_block(uuid, boolean)
from public, anon, authenticated, service_role;

grant execute
on function public.set_user_block(uuid, boolean)
to authenticated;


-- MARK: - Username policy

create or replace function public.username_is_allowed(
  p_username text
)
returns boolean
language sql
immutable
strict
security invoker
set search_path = pg_catalog
as $$
  select
    char_length(btrim(p_username)) between 3 and 24

    and btrim(p_username) ~ '^[A-Za-z0-9_]+$'

    and lower(btrim(p_username)) not in (
      'admin',
      'administrator',
      'moderator',
      'support',
      'system',
      'official',
      'gamespot',
      'game_spot'
    )

    and regexp_replace(
        lower(btrim(p_username)),
        '[^a-z0-9]',
        '',
        'g'
      ) !~ '(fuck|shit|bitch|cunt|nazi)';
$$;

create or replace function public.enforce_username_policy()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if new.username is not null then
    new.username := trim(new.username);

    if not public.username_is_allowed(new.username) then
      raise exception 'Username is not allowed'
        using errcode = '22023';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_username_policy
on public.profiles;

create trigger enforce_username_policy
before insert or update of username
on public.profiles
for each row
execute function public.enforce_username_policy();

create or replace function public.is_username_available(
  p_username text
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required'
      using errcode = '42501';
  end if;

  if p_username is null
     or not public.username_is_allowed(p_username) then
    return false;
  end if;

  return not exists (
    select 1
    from public.profiles profile
    where profile.username = trim(p_username)
  );
end;
$$;

revoke execute
on function public.username_is_allowed(text)
from public, anon, authenticated, service_role;

revoke execute
on function public.enforce_username_policy()
from public, anon, authenticated, service_role;

revoke execute
on function public.is_username_available(text)
from public, anon, authenticated, service_role;

grant execute
on function public.username_is_allowed(text)
to authenticated;

grant execute
on function public.is_username_available(text)
to authenticated;


-- MARK: - Hide blocked profiles

drop policy if exists "Realtime profiles readable"
on public.profiles;

drop policy if exists "Authenticated users can read visible profiles"
on public.profiles;

create policy "Authenticated users can read visible profiles"
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())

  or not exists (
    select 1
    from public.user_blocks block
    where block.blocker_id = (select auth.uid())
      and block.blocked_id = profiles.id
  )
);
