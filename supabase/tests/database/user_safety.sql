-- TASK-78 regression checks.
-- Run after migrations:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
--   -f supabase/tests/database/user_safety.sql

begin;

-- MARK: - Permissions and configuration

do $$
begin
  if not (
    select bool_and(table_info.relrowsecurity)
    from pg_class table_info
    join pg_namespace namespace
      on namespace.oid = table_info.relnamespace
    where namespace.nspname = 'public'
      and table_info.relname in ('user_reports', 'user_blocks')
  ) then
    raise exception 'RLS is not enabled on safety tables';
  end if;

  if has_table_privilege(
    'anon',
    'public.user_reports',
    'SELECT'
  ) or has_table_privilege(
    'anon',
    'public.user_blocks',
    'SELECT'
  ) then
    raise exception 'anon can read safety tables';
  end if;

  if has_table_privilege(
    'authenticated',
    'public.user_reports',
    'INSERT'
  ) or has_table_privilege(
    'authenticated',
    'public.user_reports',
    'UPDATE'
  ) or has_table_privilege(
    'authenticated',
    'public.user_reports',
    'DELETE'
  ) then
    raise exception 'authenticated can mutate reports directly';
  end if;

  if has_table_privilege(
    'authenticated',
    'public.user_blocks',
    'INSERT'
  ) or has_table_privilege(
    'authenticated',
    'public.user_blocks',
    'UPDATE'
  ) or has_table_privilege(
    'authenticated',
    'public.user_blocks',
    'DELETE'
  ) then
    raise exception 'authenticated can mutate blocks directly';
  end if;

  if has_function_privilege(
    'anon',
    'public.submit_user_report(uuid,text,text)',
    'EXECUTE'
  ) or has_function_privilege(
    'anon',
    'public.set_user_block(uuid,boolean)',
    'EXECUTE'
  ) then
    raise exception 'anon can execute safety RPCs';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.submit_user_report(uuid,text,text)',
    'EXECUTE'
  ) or not has_function_privilege(
    'authenticated',
    'public.set_user_block(uuid,boolean)',
    'EXECUTE'
  ) then
    raise exception 'authenticated is missing safety RPC access';
  end if;
end;
$$;


-- MARK: - Test users

insert into public.profiles (
  id,
  username,
  is_onboarded,
  is_profile_completed
)
values
  (
    '78000000-0000-4000-8000-000000000001',
    'safety_reporter',
    true,
    true
  ),
  (
    '78000000-0000-4000-8000-000000000002',
    'safety_target',
    true,
    true
  ),
  (
    '78000000-0000-4000-8000-000000000003',
    'safety_other',
    true,
    true
  );


-- MARK: - Submit and repeat a report

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '78000000-0000-4000-8000-000000000001',
  true
);

do $$
declare
  was_created boolean;
  report_count integer;
begin
  select public.submit_user_report(
    '78000000-0000-4000-8000-000000000002',
    'offensive_username',
    'Username requires review'
  )
  into was_created;

  if not was_created then
    raise exception 'first report was not created';
  end if;

  select public.submit_user_report(
    '78000000-0000-4000-8000-000000000002',
    'offensive_username',
    'Repeated report'
  )
  into was_created;

  if was_created then
    raise exception 'duplicate report was created';
  end if;

  select count(*)
  into report_count
  from public.user_reports;

  if report_count <> 1 then
    raise exception
      'reporter sees % reports, expected 1',
      report_count;
  end if;
end;
$$;


-- MARK: - Invalid reports

do $$
declare
  was_rejected boolean := false;
begin
  begin
    perform public.submit_user_report(
      '78000000-0000-4000-8000-000000000001',
      'other',
      null
    );
  exception
    when invalid_parameter_value then
      was_rejected := true;
  end;

  if not was_rejected then
    raise exception 'self-report was accepted';
  end if;

  was_rejected := false;

  begin
    perform public.submit_user_report(
      '78000000-0000-4000-8000-000000000002',
      'invalid_reason',
      null
    );
  exception
    when invalid_parameter_value then
      was_rejected := true;
  end;

  if not was_rejected then
    raise exception 'invalid report reason was accepted';
  end if;
end;
$$;


-- MARK: - Client cannot change report status

do $$
declare
  was_denied boolean := false;
begin
  begin
    update public.user_reports
    set status = 'actioned'
    where reporter_id =
      '78000000-0000-4000-8000-000000000001';
  exception
    when insufficient_privilege then
      was_denied := true;
  end;

  if not was_denied then
    raise exception 'client changed report status';
  end if;
end;
$$;

reset role;


-- MARK: - Trusted moderation can update status

set local role service_role;

update public.user_reports
set
  status = 'reviewed',
  updated_at = '2000-01-01 00:00:00+00'
where reporter_id =
  '78000000-0000-4000-8000-000000000001';

do $$
declare
  moderated_status text;
  moderated_at timestamptz;
begin
  select
    status,
    updated_at
  into
    moderated_status,
    moderated_at
  from public.user_reports
  where reporter_id =
    '78000000-0000-4000-8000-000000000001';

  if moderated_status <> 'reviewed' then
    raise exception 'trusted moderation status update failed';
  end if;

  if moderated_at <= '2000-01-01 00:00:00+00' then
    raise exception 'report updated_at was not refreshed';
  end if;
end;
$$;

reset role;


-- MARK: - Another reporter sees only their own report

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '78000000-0000-4000-8000-000000000003',
  true
);

select public.submit_user_report(
  '78000000-0000-4000-8000-000000000002',
  'other',
  null
);

do $$
declare
  visible_count integer;
begin
  select count(*)
  into visible_count
  from public.user_reports;

  if visible_count <> 1 then
    raise exception
      'second reporter sees % reports, expected 1',
      visible_count;
  end if;
end;
$$;

reset role;


-- MARK: - Reported user cannot read reports about themselves

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '78000000-0000-4000-8000-000000000002',
  true
);

do $$
declare
  visible_count integer;
begin
  select count(*)
  into visible_count
  from public.user_reports;

  if visible_count <> 0 then
    raise exception
      'reported user can read private reports';
  end if;
end;
$$;

reset role;


-- MARK: - Block is idempotent and hides profile

set local role authenticated;

select set_config(
  'request.jwt.claim.sub',
  '78000000-0000-4000-8000-000000000001',
  true
);

select public.set_user_block(
  '78000000-0000-4000-8000-000000000002',
  true
);

select public.set_user_block(
  '78000000-0000-4000-8000-000000000002',
  true
);

do $$
declare
  block_count integer;
  visible_profile_count integer;
begin
  select count(*)
  into block_count
  from public.user_blocks
  where blocked_id =
    '78000000-0000-4000-8000-000000000002';

  if block_count <> 1 then
    raise exception
      'duplicate block rows exist: %',
      block_count;
  end if;

  select count(*)
  into visible_profile_count
  from public.profiles
  where id =
    '78000000-0000-4000-8000-000000000002';

  if visible_profile_count <> 0 then
    raise exception 'blocked profile remains visible';
  end if;
end;
$$;


-- MARK: - Direct block mutation is denied

do $$
declare
  was_denied boolean := false;
begin
  begin
    delete from public.user_blocks
    where blocker_id =
      '78000000-0000-4000-8000-000000000001';
  exception
    when insufficient_privilege then
      was_denied := true;
  end;

  if not was_denied then
    raise exception 'client deleted a block directly';
  end if;
end;
$$;


-- MARK: - Unblock restores profile visibility

select public.set_user_block(
  '78000000-0000-4000-8000-000000000002',
  false
);

do $$
declare
  block_count integer;
  visible_profile_count integer;
begin
  select count(*)
  into block_count
  from public.user_blocks;

  if block_count <> 0 then
    raise exception 'block still exists after unblock';
  end if;

  select count(*)
  into visible_profile_count
  from public.profiles
  where id =
    '78000000-0000-4000-8000-000000000002';

  if visible_profile_count <> 1 then
    raise exception 'profile is not visible after unblock';
  end if;
end;
$$;


-- MARK: - Username moderation

do $$
declare
  was_rejected boolean := false;
begin
  begin
    update public.profiles
    set username = 'admin'
    where id =
      '78000000-0000-4000-8000-000000000001';
  exception
    when invalid_parameter_value then
      was_rejected := true;
  end;

  if not was_rejected then
    raise exception 'reserved username was accepted';
  end if;

  was_rejected := false;

  begin
    update public.profiles
    set username = 'F_U_C_K'
    where id =
      '78000000-0000-4000-8000-000000000001';
  exception
    when invalid_parameter_value then
      was_rejected := true;
  end;

  if not was_rejected then
    raise exception 'case-obfuscated offensive username was accepted';
  end if;

  update public.profiles
  set username = 'safe_player'
  where id =
    '78000000-0000-4000-8000-000000000001';

  if not found then
    raise exception 'valid username was not saved';
  end if;
end;
$$;

reset role;


-- MARK: - Anonymous RPC access

set local role anon;

do $$
declare
  was_denied boolean := false;
begin
  begin
    perform public.set_user_block(
      '78000000-0000-4000-8000-000000000002',
      true
    );
  exception
    when insufficient_privilege then
      was_denied := true;
  end;

  if not was_denied then
    raise exception 'anonymous block RPC call succeeded';
  end if;
end;
$$;

reset role;

rollback;
