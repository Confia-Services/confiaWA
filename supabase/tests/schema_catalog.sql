-- Catalog snapshot of the public schema as text, one row per object class.
-- Runs unchanged on confia-prod (Supabase SQL editor / MCP execute_sql) and on the local test database,
-- so the two can be compared. Platform objects (extension-owned functions, event-trigger functions) are excluded.
with cat(k, v) as (
  select 'enums', string_agg(format('%I (%s)', t.typname, (select string_agg(quote_literal(e.enumlabel), ', ' order by e.enumsortorder) from pg_enum e where e.enumtypid=t.oid)), E'\n' order by t.typname)
  from pg_type t join pg_namespace n on n.oid=t.typnamespace where n.nspname='public' and t.typtype='e'
union all
  select 'tables', string_agg(tbl, E'\n' order by tbl) from (
    select format('%I: %s', c.relname,
      (select string_agg(format('%I %s%s%s%s', a.attname, format_type(a.atttypid, a.atttypmod),
          case when a.attnotnull then ' not null' else '' end,
          case when a.attidentity='a' then ' identity always' when a.attidentity='d' then ' identity default' else '' end,
          case when a.attgenerated='s' then ' generated ('||pg_get_expr(d.adbin, d.adrelid)||')'
               when d.adbin is not null then ' default '||pg_get_expr(d.adbin, d.adrelid) else '' end
        ), ', ' order by a.attnum)
       from pg_attribute a left join pg_attrdef d on d.adrelid=a.attrelid and d.adnum=a.attnum
       where a.attrelid=c.oid and a.attnum>0 and not a.attisdropped)) as tbl
    from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p')) s
union all
  select 'constraints', string_agg(format('%I.%I %s', c.relname, k.conname, pg_get_constraintdef(k.oid)), E'\n' order by c.relname collate "C", k.conname collate "C")
  from pg_constraint k join pg_class c on c.oid=k.conrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and k.contype in ('p','u','c','f','x')
union all
  select 'indexes', string_agg(pg_get_indexdef(i.indexrelid), E'\n' order by pg_get_indexdef(i.indexrelid))
  from pg_index i join pg_class c on c.oid=i.indrelid join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and not exists (select 1 from pg_constraint k where k.conindid=i.indexrelid)
union all
  select 'rls', string_agg(format('%I enabled=%s forced=%s', c.relname, c.relrowsecurity, c.relforcerowsecurity), E'\n' order by c.relname)
  from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r'
union all
  select 'triggers', string_agg(pg_get_triggerdef(t.oid), E'\n' order by c.relname collate "C", t.tgname collate "C")
  from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and not t.tgisinternal
union all
  select 'functions', string_agg(pg_get_functiondef(p.oid), E'\n' order by p.proname collate "C", p.oid::regprocedure::text collate "C")
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.prokind in ('f','p')
    and not exists (select 1 from pg_depend d where d.objid=p.oid and d.deptype='e')
    and not exists (select 1 from pg_event_trigger et where et.evtfoid=p.oid)
union all
  select 'views', string_agg(format('%I [%s]: %s', c.relname, coalesce(array_to_string(c.reloptions, ','), ''), pg_get_viewdef(c.oid, true)), E'\n' order by c.relname)
  from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('v','m')
union all
  select 'policies', string_agg(format('%I.%I %s %s to %s using(%s) check(%s)', tablename, policyname, lower(permissive), cmd, array_to_string(roles, ','), coalesce(qual,''), coalesce(with_check,'')), E'\n' order by tablename collate "C", policyname collate "C")
  from pg_policies where schemaname='public'
union all
  select 'table_grants', string_agg(format('%s: %s', table_name, privs), E'\n' order by table_name) from (
    select table_name, string_agg(grantee||'='||p, '; ' order by grantee) as privs from (
      select table_name, grantee, string_agg(privilege_type, ',' order by privilege_type) as p
      from information_schema.role_table_grants where table_schema='public' and grantee in ('anon','authenticated','service_role','PUBLIC')
      group by table_name, grantee) g group by table_name) t
union all
  select 'function_grants', string_agg(format('%s: %s', fn, privs), E'\n' order by fn collate "C") from (
    select p.oid::regprocedure::text as fn,
           coalesce((select string_agg(r.rolname, ',' order by r.rolname) from pg_roles r
                     where r.rolname in ('anon','authenticated','service_role') and has_function_privilege(r.oid, p.oid, 'EXECUTE')), '') ||
           case when has_function_privilege(0, p.oid, 'EXECUTE') then ',PUBLIC' else '' end as privs
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind in ('f','p')
      and not exists (select 1 from pg_depend d where d.objid=p.oid and d.deptype='e')
      and not exists (select 1 from pg_event_trigger et where et.evtfoid=p.oid)) f
union all
  select 'default_acl_postgres_public', string_agg(format('%s: %s', d.defaclobjtype, d.defaclacl::text), E'\n' order by d.defaclobjtype)
  from pg_default_acl d join pg_roles r on r.oid=d.defaclrole join pg_namespace n on n.oid=d.defaclnamespace
  where r.rolname='postgres' and n.nspname='public'
union all
  select 'cron_jobs', string_agg(format('%s | %s | %s', jobname, schedule, command), E'\n' order by jobname) from cron.job
union all
  select 'storage_buckets', string_agg(format('%s public=%s limit=%s mimes=%s', id, public, file_size_limit, allowed_mime_types::text), E'\n' order by id) from storage.buckets
union all
  select 'sequences', string_agg(s.relname, ', ' order by s.relname) from pg_class s join pg_namespace n on n.oid=s.relnamespace where n.nspname='public' and s.relkind='S'
union all
  select 'pg_cron_installed', (exists (select 1 from pg_extension where extname='pg_cron'))::text
union all
  select 'seed_rows', (select format('zones=%s categories=%s services=%s settings=%s', (select count(*) from zones), (select count(*) from categories), (select count(*) from services), (select count(*) from settings)))
)
select k, v from cat order by k
