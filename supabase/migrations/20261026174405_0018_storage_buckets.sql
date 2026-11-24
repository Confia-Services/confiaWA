-- 0018 · storage buckets. Private: kyc, pgr, job-photos. Public: portfolio (approved items only; the app reads URLs from portfolio_items).
-- No storage policies for anon/authenticated: in v0 only the service role (n8n) reads and writes files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('kyc',        'kyc',        false, 10485760, array['image/jpeg','image/png','image/webp']),
  ('pgr',        'pgr',        false, 10485760, array['application/pdf','image/jpeg','image/png']),
  ('job-photos', 'job-photos', false, 10485760, array['image/jpeg','image/png','image/webp']),
  ('portfolio',  'portfolio',  true,  10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

-- anyone can view portfolio files by URL (public bucket) — but nobody except service role can list, upload or delete
create policy "portfolio public read" on storage.objects for select to anon, authenticated using (bucket_id = 'portfolio');