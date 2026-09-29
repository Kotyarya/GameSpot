-- TASK-6: keep the public avatar bucket small and image-only, while allowing
-- each authenticated user to manage objects only inside their own folder.

update storage.buckets
set file_size_limit = 5242880,
    allowed_mime_types = array[
      'image/jpeg',
      'image/png'
    ]::text[]
where id = 'avatars';

drop policy if exists "Public read avatars"
  on storage.objects;
drop policy if exists "Users insert own avatar"
  on storage.objects;
drop policy if exists "Users update own avatar"
  on storage.objects;
drop policy if exists "Users delete own avatar"
  on storage.objects;
drop policy if exists "Avatar owners can read metadata"
  on storage.objects;

-- The bucket is public, so public object downloads use the Storage public URL
-- and do not need a broad SELECT policy. This owner-only policy is required for
-- upload responses and replacements without allowing bucket-wide listing.
create policy "Avatar owners can read metadata"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'avatars'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users insert own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (select auth.uid()) is not null
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and (storage.foldername(name))[1] <> ''
);

create policy "Users update own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'avatars'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and (storage.foldername(name))[1] <> ''
);

create policy "Users delete own avatar"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
