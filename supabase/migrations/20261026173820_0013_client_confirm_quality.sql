-- 0013 · client veto, request-by-name, quality gate (decided 26 oct 2026, Javi).
create type client_response as enum ('si', 'otra', 'sin_respuesta');

alter table dispatch_offers
  add column client_response     client_response,
  add column client_responded_at timestamptz,
  add column client_expires_at   timestamptz;

create or replace function trg_job_insert() returns trigger language plpgsql as $$
declare o dispatch_offers%rowtype; q int;
begin
  select * into o from dispatch_offers where id = new.offer_id;
  if o.id is null or o.response is distinct from 'si' then
    raise exception 'job requires an offer with response = si (offer %)', new.offer_id;
  end if;
  if o.client_response is distinct from 'si' then
    raise exception 'job requires client confirmation on offer %', new.offer_id;
  end if;
  if o.pro_id <> new.pro_id or o.request_id <> new.request_id then
    raise exception 'job pro/request do not match offer %', new.offer_id;
  end if;
  if not exists (select 1 from pros where id = new.pro_id and status = 'verificada' and deleted_at is null) then
    raise exception 'pro % is not verificada', new.pro_id;
  end if;
  if exists (select 1 from jobs where pro_id = new.pro_id and status in ('aceptado','activo')) then
    select count(*) into q from jobs where pro_id = new.pro_id and status = 'en_cola';
    if q >= setting_int('queue_max', 2) then
      raise exception 'pro % already has % jobs en_cola', new.pro_id, q;
    end if;
    new.status := 'en_cola';
  else
    new.status := 'aceptado';
  end if;
  return new;
end $$;

create or replace function parse_client_reply(p_text text) returns client_response
language sql immutable as $$
  select case
    when lower(t) ~ '^\s*(si|sí|s|ok|dale|confirmo|va|claro|listo|perfecto)\s*[!.]*\s*$' then 'si'::client_response
    when lower(t) ~ '(otra|otro|cambia|prefiero|no\b)' then 'otra'::client_response
    else null end
  from (select translate(coalesce(p_text,''), 'ÁÉÍÓÚáéíóú', 'AEIOUaeiou') as t) x;
$$;

create or replace function answer_offer_client(p_offer uuid, p_raw text) returns client_response
language plpgsql as $$
declare r client_response;
begin
  r := parse_client_reply(p_raw);
  if r is null then return null; end if;
  update dispatch_offers
     set client_response = r, client_responded_at = now()
   where id = p_offer and response = 'si' and client_response is null;
  if not found then raise exception 'offer % not awaiting client confirmation', p_offer; end if;
  return r;
end $$;

create or replace view pro_card as
select p.id as pro_id, p.display_name, p.photo_url, pp.zone, pp.certified, pp.avg_rating, pp.rating_count, pp.jobs_closed,
       (select coalesce(json_agg(url), '[]'::json) from (
          select url from portfolio_items where pro_id = p.id and status = 'aprobada' order by created_at desc limit 3) t) as portfolio_3
from pros p join pro_public_profile pp on pp.id = p.id;

create or replace function cron_expire_offers() returns int language plpgsql as $$
declare n int; m int;
begin
  update dispatch_offers set response = 'sin_respuesta', responded_at = now()
   where response is null and expires_at < now();
  get diagnostics n = row_count;
  update dispatch_offers set client_response = 'sin_respuesta', client_responded_at = now()
   where response = 'si' and client_response is null and client_expires_at is not null and client_expires_at < now();
  get diagnostics m = row_count;
  return n + m;
end $$;

alter table requests add column preferred_pro_id uuid references pros(id);

create or replace function dispatch_candidates(p_request uuid)
returns table (pro_id uuid, wave offer_wave, avg_rating numeric, median_response_min double precision, rank int)
language sql stable as $$
  with rq as (
    select r.id, r.service_id, r.requested_date, r.requested_slot, r.preferred_pro_id, a.zone_id
    from requests r join client_addresses a on a.id = r.address_id
    where r.id = p_request
  ),
  cands as (
    select p.id as pro_id,
      case when exists (select 1 from jobs j where j.pro_id = p.id and j.status in ('aceptado','activo'))
           then 'con_cola'::offer_wave else 'libre'::offer_wave end as wave,
      s.avg_rating, s.median_response_min,
      (p.id = rq.preferred_pro_id) as preferred
    from pros p
    join rq on true
    join pro_services ps on ps.pro_id = p.id and ps.service_id = rq.service_id and ps.active
    join pro_stats s on s.pro_id = p.id
    where p.status = 'verificada' and p.deleted_at is null
      and p.zone_id = rq.zone_id
      and exists (select 1 from availability_slots av where av.pro_id = p.id and av.date = rq.requested_date and av.slot = rq.requested_slot)
      and not exists (select 1 from dispatch_offers o where o.request_id = rq.id and o.pro_id = p.id)
      and (select count(*) from jobs j where j.pro_id = p.id and j.status = 'en_cola') < setting_int('queue_max', 2)
  )
  select pro_id, wave, avg_rating, median_response_min,
         row_number() over (order by preferred desc, wave, avg_rating desc nulls last, median_response_min asc nulls last)::int as rank
  from cands;
$$;

insert into settings (key, value, note) values
  ('quality_min_rating', '4.2', 'auto-suspend below this over the last quality_window closed jobs — provisional'),
  ('quality_window',     '5',   'number of recent rated jobs considered'),
  ('qc_first_jobs',      '3',   'team calls the client after each of the first N jobs of a new pro')
on conflict (key) do nothing;

create or replace view pro_recent_quality as
select pro_id, round(avg(score), 2) as recent_avg, count(*) as n
from (
  select j.pro_id, r.score,
         row_number() over (partition by j.pro_id order by r.created_at desc) as rn
  from ratings r join jobs j on j.id = r.job_id
  where r.direction = 'cliente_a_pro'
) t
where rn <= setting_int('quality_window', 5)
group by pro_id;

create or replace view qc_due as
select j.id as job_id, j.pro_id, p.display_name, j.closed_at
from jobs j join pros p on p.id = j.pro_id
where j.status = 'cerrado'
  and (select count(*) from jobs j2 where j2.pro_id = j.pro_id and j2.status = 'cerrado' and j2.closed_at <= j.closed_at) <= setting_int('qc_first_jobs', 3);

create or replace function cron_quality_suspend() returns int language plpgsql as $$
declare n int;
begin
  with bad as (
    select q.pro_id from pro_recent_quality q
    where q.n >= setting_int('quality_window', 5)
      and q.recent_avg < (select (value #>> '{}')::numeric from settings where key = 'quality_min_rating')
  )
  update pros p set status = 'suspendida'
   where p.id in (select pro_id from bad) and p.status = 'verificada';
  get diagnostics n = row_count; return n;
end $$;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('quality-suspend', '15 3 * * *', 'select cron_quality_suspend()');
  end if;
end $$;