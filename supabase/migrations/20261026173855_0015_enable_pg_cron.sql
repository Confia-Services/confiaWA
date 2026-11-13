-- 0015 · enable pg_cron and schedule maintenance (0010 and 0013 skipped scheduling because the extension was off).
create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;

select cron.schedule('close-waiting-jobs', '0 * * * *',  'select cron_close_waiting_jobs()');
select cron.schedule('expire-offers',      '* * * * *',  'select cron_expire_offers()');
select cron.schedule('expire-pgr',         '0 3 * * *',  'select cron_expire_pgr()');
select cron.schedule('purge-deleted-pros', '30 3 * * *', 'select cron_purge_deleted_pros()');
select cron.schedule('scrub-messages',     '0 4 * * *',  'select cron_scrub_messages()');
select cron.schedule('quality-suspend',    '15 3 * * *', 'select cron_quality_suspend()');