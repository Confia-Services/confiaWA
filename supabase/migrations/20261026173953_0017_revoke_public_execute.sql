-- 0017 · functions are granted to PUBLIC by default; revoke that and grant explicitly.
revoke execute on all functions in schema public from public;
alter default privileges in schema public revoke execute on functions from public;
grant execute on function public.is_staff() to authenticated, service_role;
grant execute on all functions in schema public to service_role;   -- n8n