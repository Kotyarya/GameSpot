-- TASK-6 regression checks. Run after migrations with:
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/database/avatar_storage.sql

begin;

do $$
declare
  configured_limit bigint;
  configured_mimes text[];
  expected_policy_count integer;
  policy_roles name[];
begin
  select file_size_limit, allowed_mime_types
  into configured_limit, configured_mimes
  from storage.buckets
  where id = 'avatars';

  if configured_limit <> 5242880 then
    raise exception 'avatars file_size_limit is %, expected 5242880',
      configured_limit;
  end if;

  if configured_mimes is distinct from array['image/jpeg', 'image/png']::text[] then
    raise exception 'avatars allowed_mime_types are %', configured_mimes;
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'Avatar owners can read metadata',
        'Users insert own avatar',
        'Users update own avatar',
        'Users delete own avatar'
      )
      and roles <> array['authenticated']::name[]
  ) then
    raise exception 'avatar write/read policies are not authenticated-only';
  end if;

  select count(*)
  into expected_policy_count
  from pg_policies
  where schemaname = 'storage'
    and tablename = 'objects'
    and (policyname, cmd) in (
      ('Avatar owners can read metadata', 'SELECT'),
      ('Users insert own avatar', 'INSERT'),
      ('Users update own avatar', 'UPDATE'),
      ('Users delete own avatar', 'DELETE')
    );

  if expected_policy_count <> 4 then
    raise exception 'expected 4 avatar policies, found %',
      expected_policy_count;
  end if;

  select roles
  into policy_roles
  from pg_policies
  where schemaname = 'storage'
    and tablename = 'objects'
    and policyname = 'Users delete own avatar';

  if policy_roles is null then
    raise exception 'avatar delete policy is missing';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Public read avatars'
  ) then
    raise exception 'legacy bucket-wide avatar SELECT policy still exists';
  end if;
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000001',
  true
);

insert into storage.objects (
  bucket_id,
  name,
  owner_id,
  metadata
)
values (
  'avatars',
  '00000000-0000-4000-8000-000000000001/avatar.jpg',
  '00000000-0000-4000-8000-000000000001',
  '{"mimetype":"image/jpeg","size":1024}'::jsonb
);

update storage.objects
set metadata = '{"mimetype":"image/jpeg","size":2048}'::jsonb
where bucket_id = 'avatars'
  and name = '00000000-0000-4000-8000-000000000001/avatar.jpg';

do $$
declare
  denied boolean := false;
begin
  begin
    insert into storage.objects (
      bucket_id,
      name,
      owner_id,
      metadata
    ) values (
      'avatars',
      '00000000-0000-4000-8000-000000000002/avatar.jpg',
      '00000000-0000-4000-8000-000000000001',
      '{"mimetype":"image/jpeg","size":1024}'::jsonb
    );
  exception
    when insufficient_privilege then denied := true;
  end;

  if not denied then
    raise exception 'authenticated user inserted into another avatar folder';
  end if;
end;
$$;

delete from storage.objects
where bucket_id = 'avatars'
  and name = '00000000-0000-4000-8000-000000000001/avatar.jpg';

reset role;
set local role anon;

do $$
declare
  denied boolean := false;
begin
  begin
    insert into storage.objects (
      bucket_id,
      name,
      metadata
    ) values (
      'avatars',
      'anonymous/avatar.jpg',
      '{"mimetype":"image/jpeg","size":1024}'::jsonb
    );
  exception
    when insufficient_privilege then denied := true;
  end;

  if not denied then
    raise exception 'anonymous user inserted an avatar';
  end if;
end;
$$;

reset role;
rollback;
