-- 0016 · security hardening after Supabase advisors (26 oct 2026).
-- 1. Views run as the caller, so RLS on the underlying tables applies (anon sees nothing).
do $$
declare v text;
begin
  for v in select viewname from pg_views where schemaname = 'public' loop
    execute format('alter view public.%I set (security_invoker = on)', v);
  end loop;
end $$;

-- 2. Nothing in public is callable or readable by anon through the Data API. Staff (authenticated + staff row) read via RLS.
revoke all on all tables in schema public from anon;
revoke all on all functions in schema public from anon;
revoke execute on all functions in schema public from authenticated;
grant execute on function public.is_staff() to authenticated;   -- RLS policies need it
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke execute on functions from anon, authenticated;

-- 3. Pin search_path on every function in public.
do $$
declare f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prokind = 'f'
  loop
    execute format('alter function %s set search_path = public', f.sig);
  end loop;
end $$;