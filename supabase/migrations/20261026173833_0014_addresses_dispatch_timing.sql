-- 0014 · address labels + dispatch timing by same-day vs future (decided 26 oct 2026, Javi).
alter table client_addresses add column label text not null default 'Casa';
create unique index client_addresses_label on client_addresses(client_id, lower(label));

insert into settings (key, value, note) values
  ('dispatch_sameday_update_min',   '15',  'same-day request: "seguimos buscando" after N min without a pro'),
  ('dispatch_sameday_alt_min',      '45',  'same-day: offer alternative slots (where a pro is free) after N min'),
  ('dispatch_sameday_escalate_min', '60',  'same-day: hand to the team after N min'),
  ('dispatch_future_update_min',    '60',  'future-date request: update after N min'),
  ('dispatch_future_alt_min',       '240', 'future-date: offer alternatives after N min'),
  ('dispatch_future_escalate_at',   '"20:00"', 'future-date: escalate the evening before at this local time if still unassigned'),
  ('sameday_cutoff_tarde',          '"14:00"', 'last time to request same-day afternoon slot'),
  ('sameday_cutoff_noche',          '"17:00"', 'last time to request same-day evening slot')
on conflict (key) do nothing;

create or replace function request_is_sameday(p_request uuid) returns boolean
language sql stable as $$
  select r.requested_date = (now() at time zone 'America/Santo_Domingo')::date from requests r where r.id = p_request;
$$;

create or replace function alternative_slots(p_request uuid)
returns table (date date, slot time_slot, free_pros int)
language sql stable as $$
  with rq as (
    select r.service_id, a.zone_id from requests r join client_addresses a on a.id = r.address_id where r.id = p_request
  )
  select av.date, av.slot, count(distinct av.pro_id)::int
  from availability_slots av
  join pros p on p.id = av.pro_id and p.status = 'verificada' and p.deleted_at is null
  join rq on p.zone_id = rq.zone_id
  join pro_services ps on ps.pro_id = p.id and ps.service_id = rq.service_id and ps.active
  where av.date between (now() at time zone 'America/Santo_Domingo')::date and (now() at time zone 'America/Santo_Domingo')::date + 3
    and not exists (select 1 from jobs j where j.pro_id = p.id and j.status in ('aceptado','activo'))
  group by av.date, av.slot
  order by av.date, av.slot;
$$;