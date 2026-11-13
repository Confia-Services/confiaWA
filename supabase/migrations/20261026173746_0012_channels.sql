-- 0012 · channel abstraction (decided 26 oct 2026, Javi).
create type channel as enum ('whatsapp', 'instagram', 'app');

create table client_identities (
  client_id    uuid not null references clients(id) on delete cascade,
  channel      channel not null,
  external_id  text not null,
  created_at   timestamptz not null default now(),
  primary key (channel, external_id),
  unique (client_id, channel)
);
alter table client_identities enable row level security;
create policy staff_read on client_identities for select to authenticated using (is_staff());

create or replace function trg_client_wa_identity() returns trigger language plpgsql as $$
begin
  insert into client_identities(client_id, channel, external_id) values (new.id, 'whatsapp', new.phone)
  on conflict (client_id, channel) do update set external_id = excluded.external_id;
  return new;
end $$;
create trigger clients_wa_identity after insert or update of phone on clients for each row execute function trg_client_wa_identity();

alter table requests add column channel channel not null default 'whatsapp';

alter table wa_events rename to channel_events;
alter table channel_events rename column wa_message_id to external_message_id;
alter table channel_events rename column from_phone to sender_id;
alter table channel_events add column channel channel not null default 'whatsapp';
alter index if exists wa_events_unprocessed rename to channel_events_unprocessed;

alter table bot_sessions drop constraint bot_sessions_pkey;
alter table bot_sessions rename column phone to external_id;
alter table bot_sessions add column channel channel not null default 'whatsapp';
alter table bot_sessions add primary key (channel, line, external_id);

alter table messages rename column wa_in_id to external_in_id;
alter table messages rename column wa_out_id to external_out_id;

drop function if exists resolve_job_for_message(text, wa_line);
create or replace function resolve_job_for_message(p_channel channel, p_line wa_line, p_external_id text)
returns table (job_id uuid, blocked block_reason)
language plpgsql stable as $$
begin
  if p_line = 'pros' then
    return query
      select j.id, null::block_reason
      from jobs j join pros p on p.id = j.pro_id
      where p.phone = p_external_id and j.status in ('aceptado','activo')
      limit 1;
  else
    return query
      select j.id, case when j.status = 'en_cola' then 'en_cola'::block_reason else null end
      from jobs j
      join requests r on r.id = j.request_id
      join client_identities ci on ci.client_id = r.client_id and ci.channel = p_channel and ci.external_id = p_external_id
      where j.status in ('aceptado','en_cola','activo','esperando_cliente')
      order by case j.status when 'activo' then 0 when 'aceptado' then 1 when 'esperando_cliente' then 2 else 3 end
      limit 1;
  end if;
  if not found then
    return query select null::uuid, 'fuera_de_job'::block_reason;
  end if;
end $$;

create or replace function cron_scrub_messages() returns int language plpgsql as $$
declare n int;
begin
  update messages set body = null, media_url = null
   where created_at < now() - make_interval(days => setting_int('message_retention_days', 180))
     and (body is not null or media_url is not null);
  delete from channel_events where received_at < now() - make_interval(days => setting_int('message_retention_days', 180));
  get diagnostics n = row_count; return n;
end $$;