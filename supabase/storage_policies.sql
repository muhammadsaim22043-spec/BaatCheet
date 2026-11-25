-- Run in the Supabase dashboard -> SQL Editor.
-- Sets up the 'chat-images' bucket used by ChatRemoteDataSourceImpl.uploadImage().

-- Public bucket: getPublicUrl() links work without a signed URL.
-- Limit uploads to 5 MB images.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-images', 'chat-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Users sign in with Firebase, so Supabase sees every request as the 'anon' role.
-- This allows uploads (no overwrite / delete) into this bucket only.
-- NOTE: anyone holding the app's publishable key can upload here. To lock it to
-- signed-in users, enable Supabase "Third-party Auth -> Firebase" and change the
-- role below to 'authenticated'.
drop policy if exists "chat-images anon upload" on storage.objects;
create policy "chat-images anon upload"
  on storage.objects for insert
  to anon, authenticated
  with check (bucket_id = 'chat-images');

drop policy if exists "chat-images public read" on storage.objects;
create policy "chat-images public read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'chat-images');
