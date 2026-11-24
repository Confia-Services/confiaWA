-- 0000 · baseline. Schema of confia-prod (ref mymhxetdaabalragmyso) as it stood BEFORE 0011.
--
-- Why this file exists: migrations 0001–0010 were applied to confia-prod on 26 oct 2026 outside the
-- Supabase CLI, so they are not in supabase_migrations.schema_migrations and the files were lost.
-- This baseline was regenerated on 2026-11-13 from the live catalog of confia-prod (pg_catalog via the
-- Supabase MCP, equivalent to pg_dump --schema-only), and then the changes introduced by 0012–0014
-- were reversed so that  0000 + 0011 … 0018 + seed.sql  rebuilds the production schema exactly.
-- Verified with supabase/tests/run_local.sh (catalog fingerprint identical to prod).
--
-- Objects that 0012–0014 replace are reconstructed here in their pre-0012 form and marked
-- "reconstructed": their exact original text is unknown, but they are dropped or replaced by
-- 0012/0013 so the final state does not depend on them.
--
-- Platform objects are NOT here: Supabase creates them itself (schemas auth/storage/extensions,
-- the event trigger ensure_rls / rls_auto_enable, pg_cron is enabled by 0015).
--
-- On confia-prod this baseline is already applied. Register it without running it:
--   supabase migration repair --status applied 0000

-- ---------------------------------------------------------------------------------------------
-- extensions (already present on Supabase; harmless locally)
-- ---------------------------------------------------------------------------------------------
create extension if not exists pgcrypto with schema extensions;
create extension if not exists "uuid-ossp" with schema extensions;

-- ---------------------------------------------------------------------------------------------
-- enums  (channel and client_response are created by 0012 and 0013)
-- ---------------------------------------------------------------------------------------------
create type public.availability_source as enum ('diaria', 'al_pedido');
create type public.block_reason as enum ('telefono', 'llamada', 'en_cola', 'fuera_de_job');
create type public.cancel_party as enum ('pro', 'cliente', 'confia');
create type public.client_status as enum ('activo', 'bloqueado');
create type public.dispute_party as enum ('cliente', 'pro');
create type public.dispute_status as enum ('abierta', 'resuelta_cliente', 'resuelta_pro', 'cerrada');
create type public.job_actor as enum ('pro', 'cliente', 'sistema', 'staff');
create type public.job_status as enum ('aceptado', 'en_cola', 'activo', 'esperando_cliente', 'cerrado', 'cancelado', 'en_disputa');
create type public.kyc_provider as enum ('didit', 'verifik');
create type public.kyc_result as enum ('aprobado', 'rechazado', 'revision');
create type public.msg_direction as enum ('pro_a_cliente', 'cliente_a_pro', 'bot_a_pro', 'bot_a_cliente');
create type public.msg_type as enum ('text', 'audio', 'image', 'location', 'template');
create type public.offer_response as enum ('si', 'no', 'sin_respuesta', 'invalida');
create type public.offer_wave as enum ('libre', 'con_cola', 'manual');
create type public.party_type as enum ('pro', 'cliente', 'desconocido');
create type public.payment_status as enum ('pago', 'tardo', 'no_pago');
create type public.pgr_result as enum ('sin_antecedentes', 'con_antecedentes', 'no_verificable');
create type public.pricing_type as enum ('por_servicio', 'por_hora', 'mensual', 'cotizacion', 'fija_visita');
create type public.pro_status as enum ('onboarding', 'pendiente', 'verificada', 'suspendida', 'rechazada');
create type public.rating_direction as enum ('cliente_a_pro', 'pro_a_cliente');
create type public.reference_relationship as enum ('clienta', 'salon', 'colega', 'otro');
create type public.reference_status as enum ('pendiente', 'verificada', 'no_contesto', 'negativa');
create type public.request_origin as enum ('frio', 'red_personal');
create type public.request_status as enum ('abierta', 'despachando', 'asignada', 'sin_oferta', 'cancelada');
create type public.review_status as enum ('pendiente', 'aprobada', 'rechazada');
create type public.social_network as enum ('instagram', 'tiktok', 'facebook');
create type public.staff_role as enum ('admin', 'verificador', 'soporte');
create type public.time_slot as enum ('manana', 'tarde', 'noche');
create type public.verif_entity as enum ('pro', 'pro_category', 'identity', 'background', 'reference', 'portfolio', 'infotep');
create type public.verif_status as enum ('pendiente', 'verificada', 'rechazada');
create type public.wa_line as enum ('pros', 'clientes');

-- ---------------------------------------------------------------------------------------------
-- tables  (columns only; constraints and indexes follow)
-- ---------------------------------------------------------------------------------------------
create table public.settings (
  key text not null,
  value jsonb not null,
  note text
);

create table public.zones (
  id uuid not null default gen_random_uuid(),
  name text not null,
  active boolean not null default true
);

create table public.categories (
  id uuid not null default gen_random_uuid(),
  slug text not null,
  name text not null,
  color text not null,
  pricing_type pricing_type not null,
  is_urgent boolean not null default false,
  legal_hold boolean not null default false,
  requires_certificate boolean not null default false,
  active boolean not null default false,
  created_at timestamp with time zone not null default now()
);

create table public.services (
  id uuid not null default gen_random_uuid(),
  category_id uuid not null,
  slug text not null,
  name text not null,
  reference_price numeric(10,2),
  duration_min smallint,
  requires_advance_booking boolean not null default false,
  active boolean not null default true,
  created_at timestamp with time zone not null default now()
);

create table public.staff (
  id uuid not null,
  name text not null,
  role staff_role not null default 'verificador'::staff_role
);

create table public.pros (
  id uuid not null default gen_random_uuid(),
  phone text not null,
  cedula text,
  first_name text,
  last_name text,
  display_name text,
  photo_url text,
  zone_id uuid,
  status pro_status not null default 'onboarding'::pro_status,
  verified_at timestamp with time zone,
  infotep_verified_at timestamp with time zone,
  onboarding_step text,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table public.clients (
  id uuid not null default gen_random_uuid(),
  phone text not null,
  first_name text not null,
  last_name text,
  status client_status not null default 'activo'::client_status,
  blocked_reason text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- 0014 adds: label
create table public.client_addresses (
  id uuid not null default gen_random_uuid(),
  client_id uuid not null,
  zone_id uuid not null,
  line text not null,
  notes text,
  is_default boolean not null default false,
  created_at timestamp with time zone not null default now()
);

create table public.pro_categories (
  pro_id uuid not null,
  category_id uuid not null,
  status verif_status not null default 'pendiente'::verif_status,
  verified_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

create table public.pro_services (
  pro_id uuid not null,
  service_id uuid not null,
  price numeric(10,2),
  active boolean not null default true
);

create table public.identity_checks (
  id uuid not null default gen_random_uuid(),
  pro_id uuid not null,
  provider kyc_provider not null,
  provider_session_id text not null,
  cedula_match boolean,
  face_match boolean,
  liveness boolean,
  result kyc_result not null default 'revision'::kyc_result,
  checked_at timestamp with time zone not null default now()
);

create table public.background_checks (
  id uuid not null default gen_random_uuid(),
  pro_id uuid not null,
  pgr_code text not null,
  doc_url text,
  issued_at date not null,
  result pgr_result,
  verified_by uuid,
  verified_at timestamp with time zone,
  valid_until date generated always as ((issued_at + 90)) stored,
  created_at timestamp with time zone not null default now()
);

create table public."references" (
  id uuid not null default gen_random_uuid(),
  pro_id uuid not null,
  name text not null,
  phone text not null,
  relationship reference_relationship not null default 'clienta'::reference_relationship,
  status reference_status not null default 'pendiente'::reference_status,
  called_by uuid,
  called_at timestamp with time zone,
  recommends boolean,
  notes text,
  created_at timestamp with time zone not null default now()
);

create table public.portfolio_items (
  id uuid not null default gen_random_uuid(),
  pro_id uuid not null,
  category_id uuid not null,
  url text not null,
  has_face boolean not null default false,
  consent_confirmed boolean not null default false,
  status review_status not null default 'pendiente'::review_status,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

create table public.social_handles (
  pro_id uuid not null,
  network social_network not null,
  handle text not null,
  reviewed_at timestamp with time zone,
  reviewer_notes text
);

create table public.verification_events (
  id bigint not null generated always as identity,
  pro_id uuid not null,
  entity verif_entity not null,
  entity_id uuid,
  from_status text,
  to_status text,
  actor_id uuid,
  note text,
  created_at timestamp with time zone not null default now()
);

create table public.availability_slots (
  id uuid not null default gen_random_uuid(),
  pro_id uuid not null,
  date date not null,
  slot time_slot not null,
  source availability_source not null default 'diaria'::availability_source,
  created_at timestamp with time zone not null default now()
);

-- 0012 adds: channel · 0013 adds: preferred_pro_id
create table public.requests (
  id uuid not null default gen_random_uuid(),
  client_id uuid not null,
  service_id uuid not null,
  address_id uuid not null,
  requested_date date not null,
  requested_slot time_slot not null,
  notes text,
  status request_status not null default 'abierta'::request_status,
  origin request_origin,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- 0013 adds: client_response, client_responded_at, client_expires_at
create table public.dispatch_offers (
  id uuid not null default gen_random_uuid(),
  request_id uuid not null,
  pro_id uuid not null,
  rank smallint not null,
  wave offer_wave not null default 'libre'::offer_wave,
  sent_at timestamp with time zone not null default now(),
  expires_at timestamp with time zone not null,
  response offer_response,
  responded_at timestamp with time zone,
  raw_reply text
);

create table public.jobs (
  id uuid not null default gen_random_uuid(),
  request_id uuid not null,
  pro_id uuid not null,
  offer_id uuid not null,
  status job_status not null default 'aceptado'::job_status,
  scheduled_at timestamp with time zone,
  agreed_price numeric(10,2),
  completed_at timestamp with time zone,
  closed_at timestamp with time zone,
  guarantee_until date,
  cancelled_by cancel_party,
  cancel_reason text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table public.job_events (
  id bigint not null generated always as identity,
  job_id uuid not null,
  from_status job_status,
  to_status job_status not null,
  actor job_actor not null default 'sistema'::job_actor,
  note text,
  created_at timestamp with time zone not null default now()
);

create table public.job_photos (
  id uuid not null default gen_random_uuid(),
  job_id uuid not null,
  url text not null,
  uploaded_at timestamp with time zone not null default now()
);

create table public.ratings (
  id uuid not null default gen_random_uuid(),
  job_id uuid not null,
  direction rating_direction not null,
  score smallint not null,
  comment text,
  created_at timestamp with time zone not null default now()
);

create table public.payment_records (
  job_id uuid not null,
  status payment_status not null,
  noted_at timestamp with time zone not null default now()
);

create table public.tips (
  job_id uuid not null,
  amount numeric(10,2) not null,
  declared_at timestamp with time zone not null default now()
);

create table public.disputes (
  id uuid not null default gen_random_uuid(),
  job_id uuid not null,
  opened_by dispute_party not null,
  reason text not null,
  status dispute_status not null default 'abierta'::dispute_status,
  handled_by uuid,
  resolved_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

-- 0012 renames this table to channel_events (wa_message_id → external_message_id, from_phone → sender_id) and adds channel
create table public.wa_events (
  wa_message_id text not null,
  line wa_line not null,
  from_phone text not null,
  payload jsonb not null,
  received_at timestamp with time zone not null default now(),
  processed_at timestamp with time zone
);

-- 0012 renames phone → external_id, adds channel and re-keys by (channel, line, external_id)
create table public.bot_sessions (
  phone text not null,
  line wa_line not null,
  party_type party_type not null default 'desconocido'::party_type,
  party_id uuid,
  state text not null default 'idle'::text,
  context jsonb not null default '{}'::jsonb,
  updated_at timestamp with time zone not null default now()
);

-- 0012 renames wa_in_id → external_in_id, wa_out_id → external_out_id
create table public.messages (
  id uuid not null default gen_random_uuid(),
  job_id uuid not null,
  direction msg_direction not null,
  type msg_type not null default 'text'::msg_type,
  body text,
  media_url text,
  wa_in_id text,
  wa_out_id text,
  blocked_reason block_reason,
  created_at timestamp with time zone not null default now()
);

-- ---------------------------------------------------------------------------------------------
-- constraints
-- ---------------------------------------------------------------------------------------------
alter table public.availability_slots add constraint availability_slots_pkey PRIMARY KEY (id);
alter table public.background_checks add constraint background_checks_pkey PRIMARY KEY (id);
alter table public.bot_sessions add constraint bot_sessions_pkey PRIMARY KEY (line, phone);   -- reconstructed; dropped by 0012
alter table public.categories add constraint categories_pkey PRIMARY KEY (id);
alter table public.wa_events add constraint wa_events_pkey PRIMARY KEY (wa_message_id);
alter table public.client_addresses add constraint client_addresses_pkey PRIMARY KEY (id);
alter table public.clients add constraint clients_pkey PRIMARY KEY (id);
alter table public.dispatch_offers add constraint dispatch_offers_pkey PRIMARY KEY (id);
alter table public.disputes add constraint disputes_pkey PRIMARY KEY (id);
alter table public.identity_checks add constraint identity_checks_pkey PRIMARY KEY (id);
alter table public.job_events add constraint job_events_pkey PRIMARY KEY (id);
alter table public.job_photos add constraint job_photos_pkey PRIMARY KEY (id);
alter table public.jobs add constraint jobs_pkey PRIMARY KEY (id);
alter table public.messages add constraint messages_pkey PRIMARY KEY (id);
alter table public.payment_records add constraint payment_records_pkey PRIMARY KEY (job_id);
alter table public.portfolio_items add constraint portfolio_items_pkey PRIMARY KEY (id);
alter table public.pro_categories add constraint pro_categories_pkey PRIMARY KEY (pro_id, category_id);
alter table public.pro_services add constraint pro_services_pkey PRIMARY KEY (pro_id, service_id);
alter table public.pros add constraint pros_pkey PRIMARY KEY (id);
alter table public.ratings add constraint ratings_pkey PRIMARY KEY (id);
alter table public."references" add constraint references_pkey PRIMARY KEY (id);
alter table public.requests add constraint requests_pkey PRIMARY KEY (id);
alter table public.services add constraint services_pkey PRIMARY KEY (id);
alter table public.settings add constraint settings_pkey PRIMARY KEY (key);
alter table public.social_handles add constraint social_handles_pkey PRIMARY KEY (pro_id, network);
alter table public.staff add constraint staff_pkey PRIMARY KEY (id);
alter table public.tips add constraint tips_pkey PRIMARY KEY (job_id);
alter table public.verification_events add constraint verification_events_pkey PRIMARY KEY (id);
alter table public.zones add constraint zones_pkey PRIMARY KEY (id);

alter table public.availability_slots add constraint availability_slots_pro_id_date_slot_key UNIQUE (pro_id, date, slot);
alter table public.background_checks add constraint background_checks_pgr_code_key UNIQUE (pgr_code);
alter table public.categories add constraint categories_slug_key UNIQUE (slug);
alter table public.clients add constraint clients_phone_key UNIQUE (phone);
alter table public.dispatch_offers add constraint dispatch_offers_request_id_pro_id_key UNIQUE (request_id, pro_id);
alter table public.identity_checks add constraint identity_checks_provider_session_id_key UNIQUE (provider_session_id);
alter table public.jobs add constraint jobs_offer_id_key UNIQUE (offer_id);
alter table public.jobs add constraint jobs_request_id_key UNIQUE (request_id);
alter table public.pros add constraint pros_cedula_key UNIQUE (cedula);
alter table public.pros add constraint pros_phone_key UNIQUE (phone);
alter table public.ratings add constraint ratings_job_id_direction_key UNIQUE (job_id, direction);
alter table public.services add constraint services_slug_key UNIQUE (slug);
alter table public.zones add constraint zones_name_key UNIQUE (name);

alter table public.categories add constraint categories_color_check CHECK ((color ~ '^#[0-9A-Fa-f]{6}$'::text));
alter table public.clients add constraint clients_phone_check CHECK ((phone ~ '^\+[1-9][0-9]{7,14}$'::text));
alter table public.portfolio_items add constraint portfolio_items_check CHECK (((NOT has_face) OR consent_confirmed));
alter table public.pros add constraint pros_cedula_check CHECK ((cedula ~ '^[0-9]{11}$'::text));
alter table public.pros add constraint pros_phone_check CHECK ((phone ~ '^\+[1-9][0-9]{7,14}$'::text));
alter table public.ratings add constraint ratings_score_check CHECK (((score >= 1) AND (score <= 5)));
alter table public.tips add constraint tips_amount_check CHECK ((amount > (0)::numeric));

alter table public.availability_slots add constraint availability_slots_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id) ON DELETE CASCADE;
alter table public.background_checks add constraint background_checks_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id) ON DELETE CASCADE;
alter table public.background_checks add constraint background_checks_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES staff(id);
alter table public.client_addresses add constraint client_addresses_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.client_addresses add constraint client_addresses_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES zones(id);
alter table public.dispatch_offers add constraint dispatch_offers_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id);
alter table public.dispatch_offers add constraint dispatch_offers_request_id_fkey FOREIGN KEY (request_id) REFERENCES requests(id) ON DELETE CASCADE;
alter table public.disputes add constraint disputes_handled_by_fkey FOREIGN KEY (handled_by) REFERENCES staff(id);
alter table public.disputes add constraint disputes_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
alter table public.identity_checks add constraint identity_checks_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id) ON DELETE CASCADE;
alter table public.job_events add constraint job_events_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
alter table public.job_photos add constraint job_photos_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
alter table public.jobs add constraint jobs_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES dispatch_offers(id);
alter table public.jobs add constraint jobs_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id);
alter table public.jobs add constraint jobs_request_id_fkey FOREIGN KEY (request_id) REFERENCES requests(id);
alter table public.messages add constraint messages_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
alter table public.payment_records add constraint payment_records_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
alter table public.portfolio_items add constraint portfolio_items_pro_id_category_id_fkey FOREIGN KEY (pro_id, category_id) REFERENCES pro_categories(pro_id, category_id) ON DELETE CASCADE;
alter table public.portfolio_items add constraint portfolio_items_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES staff(id);
alter table public.pro_categories add constraint pro_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);
alter table public.pro_categories add constraint pro_categories_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id) ON DELETE CASCADE;
alter table public.pro_services add constraint pro_services_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id) ON DELETE CASCADE;
alter table public.pro_services add constraint pro_services_service_id_fkey FOREIGN KEY (service_id) REFERENCES services(id);
alter table public.pros add constraint pros_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES zones(id);
alter table public.ratings add constraint ratings_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
alter table public."references" add constraint references_called_by_fkey FOREIGN KEY (called_by) REFERENCES staff(id);
alter table public."references" add constraint references_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id) ON DELETE CASCADE;
alter table public.requests add constraint requests_address_id_fkey FOREIGN KEY (address_id) REFERENCES client_addresses(id);
alter table public.requests add constraint requests_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id);
alter table public.requests add constraint requests_service_id_fkey FOREIGN KEY (service_id) REFERENCES services(id);
alter table public.services add constraint services_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(id);
alter table public.social_handles add constraint social_handles_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id) ON DELETE CASCADE;
alter table public.staff add constraint staff_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.tips add constraint tips_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
alter table public.verification_events add constraint verification_events_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES staff(id);
alter table public.verification_events add constraint verification_events_pro_id_fkey FOREIGN KEY (pro_id) REFERENCES pros(id) ON DELETE CASCADE;

-- ---------------------------------------------------------------------------------------------
-- indexes  (client_addresses_label is created by 0014)
-- ---------------------------------------------------------------------------------------------
CREATE INDEX availability_slots_date_slot_idx ON public.availability_slots USING btree (date, slot);
CREATE INDEX background_checks_pro_id_idx ON public.background_checks USING btree (pro_id);
CREATE INDEX wa_events_unprocessed ON public.wa_events USING btree (received_at) WHERE (processed_at IS NULL);   -- renamed by 0012
CREATE INDEX client_addresses_client_id_idx ON public.client_addresses USING btree (client_id);
CREATE UNIQUE INDEX client_addresses_one_default ON public.client_addresses USING btree (client_id) WHERE is_default;
CREATE INDEX dispatch_offers_pending ON public.dispatch_offers USING btree (expires_at) WHERE (response IS NULL);
CREATE INDEX dispatch_offers_pro_id_sent_at_idx ON public.dispatch_offers USING btree (pro_id, sent_at);
CREATE UNIQUE INDEX disputes_one_open_per_job ON public.disputes USING btree (job_id) WHERE (status = 'abierta'::dispute_status);
CREATE INDEX identity_checks_pro_id_idx ON public.identity_checks USING btree (pro_id);
CREATE INDEX job_events_job_id_created_at_idx ON public.job_events USING btree (job_id, created_at);
CREATE INDEX job_photos_job_id_idx ON public.job_photos USING btree (job_id);
CREATE UNIQUE INDEX jobs_one_active_per_pro ON public.jobs USING btree (pro_id) WHERE (status = ANY (ARRAY['aceptado'::job_status, 'activo'::job_status]));
CREATE INDEX jobs_pro_id_status_idx ON public.jobs USING btree (pro_id, status);
CREATE INDEX messages_job_id_created_at_idx ON public.messages USING btree (job_id, created_at);
CREATE INDEX portfolio_items_pro_id_status_idx ON public.portfolio_items USING btree (pro_id, status);
CREATE INDEX pros_status_idx ON public.pros USING btree (status) WHERE (deleted_at IS NULL);
CREATE INDEX pros_zone_id_idx ON public.pros USING btree (zone_id);
CREATE INDEX references_pro_id_idx ON public."references" USING btree (pro_id);
CREATE INDEX requests_client_id_idx ON public.requests USING btree (client_id);
CREATE INDEX requests_status_idx ON public.requests USING btree (status);
CREATE INDEX services_category_id_idx ON public.services USING btree (category_id);
CREATE INDEX verification_events_pro_id_created_at_idx ON public.verification_events USING btree (pro_id, created_at);

-- ---------------------------------------------------------------------------------------------
-- functions
-- (parse_client_reply, answer_offer_client, cron_quality_suspend come from 0013;
--  request_is_sameday, alternative_slots from 0014; trg_client_wa_identity from 0012)
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.setting_int(p_key text, p_default integer)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
begin
  return coalesce((select (value #>> '{}')::int from settings where key = p_key), p_default);
end $function$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  new.updated_at = now();
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.is_staff()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from staff where id = auth.uid());
$function$;

CREATE OR REPLACE FUNCTION public.log_verification_event(p_pro uuid, p_entity verif_entity, p_entity_id uuid, p_from text, p_to text, p_actor uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE sql
 SET search_path TO 'public'
AS $function$
  insert into verification_events(pro_id, entity, entity_id, from_status, to_status, actor_id, note)
  values (p_pro, p_entity, p_entity_id, p_from, p_to, p_actor, p_note);
$function$;

CREATE OR REPLACE FUNCTION public.trg_log_identity()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' or old.result is distinct from new.result then
    perform log_verification_event(new.pro_id, 'identity', new.id, case when tg_op='INSERT' then null else old.result::text end, new.result::text);
  end if; return new;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_log_background()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' or old.result is distinct from new.result then
    perform log_verification_event(new.pro_id, 'background', new.id, case when tg_op='INSERT' then null else old.result::text end, new.result::text, new.verified_by);
  end if; return new;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_log_reference()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' or old.status is distinct from new.status then
    perform log_verification_event(new.pro_id, 'reference', new.id, case when tg_op='INSERT' then null else old.status::text end, new.status::text, new.called_by);
  end if; return new;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_log_portfolio()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' or old.status is distinct from new.status then
    perform log_verification_event(new.pro_id, 'portfolio', new.id, case when tg_op='INSERT' then null else old.status::text end, new.status::text, new.reviewed_by);
  end if; return new;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_log_pro_category()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' or old.status is distinct from new.status then
    perform log_verification_event(new.pro_id, 'pro_category', new.category_id, case when tg_op='INSERT' then null else old.status::text end, new.status::text);
  end if; return new;
end $function$;

CREATE OR REPLACE FUNCTION public.verification_missing(p_pro uuid)
 RETURNS text[]
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  select array_remove(array[
    case when not exists (select 1 from identity_checks where pro_id = p_pro and result = 'aprobado') then 'kyc' end,
    case when not exists (select 1 from background_checks where pro_id = p_pro and result = 'sin_antecedentes' and valid_until >= current_date) then 'pgr' end,
    case when (select count(*) from "references" where pro_id = p_pro and status = 'verificada' and recommends) < 2 then 'referencias' end,
    case when (select count(*) from portfolio_items where pro_id = p_pro and status = 'aprobada') < setting_int('portfolio_min', 3) then 'portafolio' end,
    case when not exists (select 1 from pro_categories where pro_id = p_pro and status = 'verificada') then 'categoria' end,
    case when (select display_name is null or zone_id is null from pros where id = p_pro) then 'perfil' end
  ], null);
$function$;

CREATE OR REPLACE FUNCTION public.trg_pro_status_gate()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare missing text[];
begin
  if new.status = 'verificada' and (tg_op = 'INSERT' or old.status is distinct from 'verificada') then
    missing := verification_missing(new.id);
    if coalesce(array_length(missing, 1), 0) > 0 then
      raise exception 'pro % cannot be verificada; missing: %', new.id, array_to_string(missing, ', ');
    end if;
    new.verified_at := now();
  end if;
  if tg_op = 'UPDATE' and old.status is distinct from new.status then
    perform log_verification_event(new.id, 'pro', new.id, old.status::text, new.status::text);
  end if;
  if tg_op = 'UPDATE' and old.infotep_verified_at is null and new.infotep_verified_at is not null then
    perform log_verification_event(new.id, 'infotep', new.id, null, 'verificada');
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.check_pro_service_category()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if not exists (
    select 1 from services s
    join pro_categories pc on pc.category_id = s.category_id and pc.pro_id = new.pro_id
    where s.id = new.service_id
  ) then
    raise exception 'pro % has not enrolled in the category of service %', new.pro_id, new.service_id;
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.parse_offer_reply(p_text text)
 RETURNS offer_response
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  select case
    when lower(unaccent_free) ~ '^\s*(si|sí|s|ok|oka|okey|dale|voy|va|claro|de una|listo|acepto)\s*[!.]*\s*$' then 'si'::offer_response
    when lower(unaccent_free) ~ '^\s*(no|nel|no puedo|no voy|paso|nop|no gracias)\s*[!.]*\s*$' then 'no'::offer_response
    else 'invalida'::offer_response
  end
  from (select translate(coalesce(p_text,''), 'ÁÉÍÓÚáéíóú', 'AEIOUaeiou') as unaccent_free) t;
$function$;

CREATE OR REPLACE FUNCTION public.answer_offer(p_offer uuid, p_raw text)
 RETURNS offer_response
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare r offer_response;
begin
  r := parse_offer_reply(p_raw);
  update dispatch_offers
     set response = r, responded_at = now(), raw_reply = p_raw
   where id = p_offer and response is null;
  if not found then raise exception 'offer % already answered or missing', p_offer; end if;
  return r;
end $function$;

-- reconstructed pre-0013 version (no client confirmation yet); replaced by 0013
CREATE OR REPLACE FUNCTION public.trg_job_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare o dispatch_offers%rowtype; q int;
begin
  select * into o from dispatch_offers where id = new.offer_id;
  if o.id is null or o.response is distinct from 'si' then
    raise exception 'job requires an offer with response = si (offer %)', new.offer_id;
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
end $function$;

CREATE OR REPLACE FUNCTION public.trg_job_after_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  insert into job_events(job_id, from_status, to_status, actor) values (new.id, null, new.status, 'sistema');
  update requests set status = 'asignada' where id = new.request_id;
  -- close any other pending offers for this request
  update dispatch_offers set response = 'sin_respuesta', responded_at = now()
    where request_id = new.request_id and id <> new.offer_id and response is null;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_job_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare allowed boolean; nxt uuid;
begin
  if old.status = new.status then return new; end if;

  allowed := case old.status
    when 'en_cola'            then new.status in ('aceptado','cancelado')
    when 'aceptado'           then new.status in ('activo','cancelado')
    when 'activo'             then new.status in ('esperando_cliente','cancelado')
    when 'esperando_cliente'  then new.status in ('cerrado')
    when 'cerrado'            then new.status in ('en_disputa')
    when 'en_disputa'         then new.status in ('cerrado')
    else false end;
  if not allowed then
    raise exception 'job %: transition % → % not allowed', old.id, old.status, new.status;
  end if;

  if new.status = 'esperando_cliente' then
    if not exists (select 1 from job_photos where job_id = new.id) then
      raise exception 'job %: at least one photo required before listo', new.id;
    end if;
    new.completed_at := coalesce(new.completed_at, now());
  end if;

  if new.status = 'cerrado' and old.status = 'esperando_cliente' then
    new.closed_at := coalesce(new.closed_at, now());
    new.guarantee_until := (new.closed_at + make_interval(days => setting_int('guarantee_days', 7)))::date;
  end if;

  if new.status = 'en_disputa' and (old.guarantee_until is null or old.guarantee_until < current_date) then
    raise exception 'job %: guarantee expired', old.id;
  end if;

  if new.status = 'cancelado' and new.cancelled_by is null then
    raise exception 'job %: cancelled_by required', old.id;
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_job_status_after()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare nxt uuid;
begin
  if old.status = new.status then return new; end if;
  insert into job_events(job_id, from_status, to_status, actor) values (new.id, old.status, new.status, 'sistema');

  if old.status in ('aceptado','activo') and new.status in ('esperando_cliente','cancelado') then
    -- the open chat is now free (esperando_cliente no longer blocks the pro)
    select id into nxt from jobs where pro_id = new.pro_id and status = 'en_cola' order by created_at limit 1;
    if nxt is not null then
      update jobs set status = 'aceptado' where id = nxt;
    end if;
  end if;
  if new.status = 'cancelado' then
    update requests set status = 'abierta' where id = new.request_id and status = 'asignada';
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_rating_closes()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if new.direction = 'cliente_a_pro' then
    update jobs set status = 'cerrado' where id = new.job_id and status = 'esperando_cliente';
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_dispute()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' then
    update jobs set status = 'en_disputa' where id = new.job_id;
  elsif old.status = 'abierta' and new.status <> 'abierta' then
    new.resolved_at := coalesce(new.resolved_at, now());
    update jobs set status = 'cerrado' where id = new.job_id and status = 'en_disputa';
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.relay_block_reason(p_text text)
 RETURNS block_reason
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  select case
    when p_text ~ '8[024]9[\s.-]?\d{3}[\s.-]?\d{4}' then 'telefono'::block_reason
    when lower(p_text) ~ '(ll[aá]m|n[uú]mero|whats|tel[eé]fono|cel\b|celular)' then 'llamada'::block_reason
    else null end;
$function$;

-- reconstructed pre-0012 version (phone-keyed); dropped and recreated with a channel parameter by 0012
CREATE OR REPLACE FUNCTION public.resolve_job_for_message(p_phone text, p_line wa_line)
 RETURNS TABLE(job_id uuid, blocked block_reason)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
begin
  if p_line = 'pros' then
    return query
      select j.id, null::block_reason
      from jobs j join pros p on p.id = j.pro_id
      where p.phone = p_phone and j.status in ('aceptado','activo')
      limit 1;
  else
    return query
      select j.id, case when j.status = 'en_cola' then 'en_cola'::block_reason else null end
      from jobs j
      join requests r on r.id = j.request_id
      join clients c on c.id = r.client_id and c.phone = p_phone
      where j.status in ('aceptado','en_cola','activo','esperando_cliente')
      order by case j.status when 'activo' then 0 when 'aceptado' then 1 when 'esperando_cliente' then 2 else 3 end
      limit 1;
  end if;
  if not found then
    return query select null::uuid, 'fuera_de_job'::block_reason;
  end if;
end $function$;

CREATE OR REPLACE FUNCTION public.trg_message_activates_job()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if new.blocked_reason is null and new.direction in ('pro_a_cliente','cliente_a_pro') then
    update jobs set status = 'activo' where id = new.job_id and status = 'aceptado';
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.cron_close_waiting_jobs()
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  update jobs set status = 'cerrado'
   where status = 'esperando_cliente'
     and completed_at < now() - make_interval(hours => setting_int('client_close_hours', 24));
  get diagnostics n = row_count; return n;
end $function$;

-- reconstructed pre-0013 version (no client confirmation expiry); replaced by 0013
CREATE OR REPLACE FUNCTION public.cron_expire_offers()
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  update dispatch_offers set response = 'sin_respuesta', responded_at = now()
   where response is null and expires_at < now();
  get diagnostics n = row_count; return n;
end $function$;

CREATE OR REPLACE FUNCTION public.cron_expire_pgr()
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  update pros p set status = 'pendiente'
   where p.status = 'verificada'
     and not exists (select 1 from background_checks b where b.pro_id = p.id and b.result = 'sin_antecedentes' and b.valid_until >= current_date);
  get diagnostics n = row_count; return n;
end $function$;

CREATE OR REPLACE FUNCTION public.cron_purge_deleted_pros()
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  with gone as (
    select id from pros where deleted_at < now() - interval '30 days' and cedula is not null
  ),
  d1 as (delete from identity_checks   where pro_id in (select id from gone)),
  d2 as (delete from background_checks where pro_id in (select id from gone)),
  d3 as (delete from "references"      where pro_id in (select id from gone)),
  d4 as (delete from social_handles    where pro_id in (select id from gone)),
  d5 as (delete from portfolio_items   where pro_id in (select id from gone))
  update pros set cedula = null, first_name = null, last_name = null, photo_url = null,
                  phone = '+000' || lpad((random()*1e12)::bigint::text, 12, '0'),   -- unique placeholder
                  display_name = 'Pro eliminada'
   where id in (select id from gone);
  get diagnostics n = row_count; return n;
end $function$;

-- reconstructed pre-0012 version (wa_events); replaced by 0012
CREATE OR REPLACE FUNCTION public.cron_scrub_messages()
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare n int;
begin
  update messages set body = null, media_url = null
   where created_at < now() - make_interval(days => setting_int('message_retention_days', 180))
     and (body is not null or media_url is not null);
  delete from wa_events where received_at < now() - make_interval(days => setting_int('message_retention_days', 180));
  get diagnostics n = row_count; return n;
end $function$;

-- ---------------------------------------------------------------------------------------------
-- views  (0016 switches them all to security_invoker; pro_card, pro_recent_quality, qc_due come from 0013)
-- ---------------------------------------------------------------------------------------------
create view public.pro_stats as
 SELECT p.id AS pro_id,
    count(DISTINCT j.id) FILTER (WHERE j.status = 'cerrado'::job_status) AS jobs_closed,
    round(avg(r.score) FILTER (WHERE r.direction = 'cliente_a_pro'::rating_direction), 2) AS avg_rating,
    count(r.id) FILTER (WHERE r.direction = 'cliente_a_pro'::rating_direction) AS rating_count,
    ( SELECT percentile_cont(0.5::double precision) WITHIN GROUP (ORDER BY ((EXTRACT(epoch FROM o.responded_at - o.sent_at) / 60::numeric)::double precision)) AS percentile_cont
           FROM dispatch_offers o
          WHERE o.pro_id = p.id AND o.responded_at IS NOT NULL) AS median_response_min,
    ( SELECT round(count(*) FILTER (WHERE o.response = 'si'::offer_response)::numeric / NULLIF(count(*), 0)::numeric, 2) AS round
           FROM dispatch_offers o
          WHERE o.pro_id = p.id AND o.response IS NOT NULL) AS acceptance_rate,
    ( SELECT count(*) AS count
           FROM ( SELECT rq.client_id
                   FROM jobs j2
                     JOIN requests rq ON rq.id = j2.request_id
                  WHERE j2.pro_id = p.id AND j2.status = 'cerrado'::job_status
                  GROUP BY rq.client_id
                 HAVING count(*) > 1) t) AS repeat_clients
   FROM pros p
     LEFT JOIN jobs j ON j.pro_id = p.id
     LEFT JOIN ratings r ON r.job_id = j.id
  GROUP BY p.id;

create view public.pro_public_profile as
 SELECT p.id,
    p.display_name,
    p.photo_url,
    z.name AS zone,
    p.status = 'verificada'::pro_status AS verified,
    p.infotep_verified_at IS NOT NULL AS certified,
    s.avg_rating,
    s.rating_count,
    s.jobs_closed,
    s.median_response_min,
    ( SELECT COALESCE(json_agg(json_build_object('service', sv.name, 'price', ps.price, 'category', c.slug)), '[]'::json) AS "coalesce"
           FROM pro_services ps
             JOIN services sv ON sv.id = ps.service_id
             JOIN categories c ON c.id = sv.category_id
          WHERE ps.pro_id = p.id AND ps.active AND sv.active AND c.active AND NOT c.legal_hold) AS services,
    ( SELECT COALESCE(json_agg(pi.url), '[]'::json) AS "coalesce"
           FROM portfolio_items pi
          WHERE pi.pro_id = p.id AND pi.status = 'aprobada'::review_status) AS portfolio
   FROM pros p
     JOIN pro_stats s ON s.pro_id = p.id
     LEFT JOIN zones z ON z.id = p.zone_id
  WHERE p.status = 'verificada'::pro_status AND p.deleted_at IS NULL;

create view public.client_stats as
 SELECT c.id AS client_id,
    round(avg(r.score) FILTER (WHERE r.direction = 'pro_a_cliente'::rating_direction), 2) AS avg_rating_by_pros,
    count(DISTINCT j.id) FILTER (WHERE j.status = 'cerrado'::job_status) AS jobs_closed,
    count(DISTINCT pr.job_id) FILTER (WHERE pr.status = 'no_pago'::payment_status) AS no_pago_count,
    count(DISTINCT pr.job_id) FILTER (WHERE pr.status = 'tardo'::payment_status) AS tardo_count
   FROM clients c
     LEFT JOIN requests rq ON rq.client_id = c.id
     LEFT JOIN jobs j ON j.request_id = rq.id
     LEFT JOIN ratings r ON r.job_id = j.id
     LEFT JOIN payment_records pr ON pr.job_id = j.id
  GROUP BY c.id;

create view public.verification_checklist as
 SELECT id AS pro_id,
    display_name,
    status,
    verification_missing(id) AS missing
   FROM pros p
  WHERE deleted_at IS NULL;

create view public.signals as
 SELECT date_trunc('week'::text, j.closed_at)::date AS week,
    count(*) FILTER (WHERE r.origin = 'frio'::request_origin) AS cold_jobs_closed,
    count(*) FILTER (WHERE r.origin = 'red_personal'::request_origin) AS network_jobs_closed,
    count(DISTINCT r.client_id) FILTER (WHERE (( SELECT count(*) AS count
           FROM requests r2
             JOIN jobs j2 ON j2.request_id = r2.id
          WHERE r2.client_id = r.client_id AND j2.status = 'cerrado'::job_status)) > 1) AS repeat_clients,
    ( SELECT count(*) AS count
           FROM pros
          WHERE pros.status = 'verificada'::pro_status AND pros.deleted_at IS NULL) AS verified_pros
   FROM jobs j
     JOIN requests r ON r.id = j.request_id
  WHERE j.status = 'cerrado'::job_status
  GROUP BY (date_trunc('week'::text, j.closed_at)::date)
  ORDER BY (date_trunc('week'::text, j.closed_at)::date);

-- reconstructed pre-0013 version (no preferred_pro_id); replaced by 0013. Depends on pro_stats, hence after the views.
CREATE OR REPLACE FUNCTION public.dispatch_candidates(p_request uuid)
 RETURNS TABLE(pro_id uuid, wave offer_wave, avg_rating numeric, median_response_min double precision, rank integer)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  with rq as (
    select r.id, r.service_id, r.requested_date, r.requested_slot, a.zone_id
    from requests r join client_addresses a on a.id = r.address_id
    where r.id = p_request
  ),
  cands as (
    select p.id as pro_id,
      case when exists (select 1 from jobs j where j.pro_id = p.id and j.status in ('aceptado','activo'))
           then 'con_cola'::offer_wave else 'libre'::offer_wave end as wave,
      s.avg_rating, s.median_response_min
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
         row_number() over (order by wave, avg_rating desc nulls last, median_response_min asc nulls last)::int as rank
  from cands;
$function$;

-- ---------------------------------------------------------------------------------------------
-- triggers  (clients_wa_identity comes from 0012)
-- ---------------------------------------------------------------------------------------------
CREATE TRIGGER background_checks_log AFTER INSERT OR UPDATE ON public.background_checks FOR EACH ROW EXECUTE FUNCTION trg_log_background();
CREATE TRIGGER bot_sessions_updated_at BEFORE UPDATE ON public.bot_sessions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER clients_updated_at BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER disputes_sync BEFORE INSERT OR UPDATE ON public.disputes FOR EACH ROW EXECUTE FUNCTION trg_dispute();
CREATE TRIGGER identity_checks_log AFTER INSERT OR UPDATE ON public.identity_checks FOR EACH ROW EXECUTE FUNCTION trg_log_identity();
CREATE TRIGGER jobs_after_insert AFTER INSERT ON public.jobs FOR EACH ROW EXECUTE FUNCTION trg_job_after_insert();
CREATE TRIGGER jobs_insert_rules BEFORE INSERT ON public.jobs FOR EACH ROW EXECUTE FUNCTION trg_job_insert();
CREATE TRIGGER jobs_status_after AFTER UPDATE OF status ON public.jobs FOR EACH ROW EXECUTE FUNCTION trg_job_status_after();
CREATE TRIGGER jobs_status_rules BEFORE UPDATE OF status ON public.jobs FOR EACH ROW EXECUTE FUNCTION trg_job_status();
CREATE TRIGGER jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER messages_activate_job AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION trg_message_activates_job();
CREATE TRIGGER portfolio_items_log AFTER INSERT OR UPDATE ON public.portfolio_items FOR EACH ROW EXECUTE FUNCTION trg_log_portfolio();
CREATE TRIGGER pro_categories_log AFTER INSERT OR UPDATE ON public.pro_categories FOR EACH ROW EXECUTE FUNCTION trg_log_pro_category();
CREATE TRIGGER pro_services_category_check BEFORE INSERT OR UPDATE ON public.pro_services FOR EACH ROW EXECUTE FUNCTION check_pro_service_category();
CREATE TRIGGER pros_status_gate BEFORE INSERT OR UPDATE ON public.pros FOR EACH ROW EXECUTE FUNCTION trg_pro_status_gate();
CREATE TRIGGER pros_updated_at BEFORE UPDATE ON public.pros FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER ratings_close_job AFTER INSERT ON public.ratings FOR EACH ROW EXECUTE FUNCTION trg_rating_closes();
CREATE TRIGGER references_log AFTER INSERT OR UPDATE ON public."references" FOR EACH ROW EXECUTE FUNCTION trg_log_reference();
CREATE TRIGGER requests_updated_at BEFORE UPDATE ON public.requests FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------------------------
-- RLS: service role writes; staff (authenticated + staff row) reads, and edits verification/disputes/config.
-- (client_identities policy comes from 0012)
-- ---------------------------------------------------------------------------------------------
alter table public.availability_slots enable row level security;
alter table public.background_checks enable row level security;
alter table public.bot_sessions enable row level security;
alter table public.categories enable row level security;
alter table public.wa_events enable row level security;
alter table public.client_addresses enable row level security;
alter table public.clients enable row level security;
alter table public.dispatch_offers enable row level security;
alter table public.disputes enable row level security;
alter table public.identity_checks enable row level security;
alter table public.job_events enable row level security;
alter table public.job_photos enable row level security;
alter table public.jobs enable row level security;
alter table public.messages enable row level security;
alter table public.payment_records enable row level security;
alter table public.portfolio_items enable row level security;
alter table public.pro_categories enable row level security;
alter table public.pro_services enable row level security;
alter table public.pros enable row level security;
alter table public.ratings enable row level security;
alter table public."references" enable row level security;
alter table public.requests enable row level security;
alter table public.services enable row level security;
alter table public.settings enable row level security;
alter table public.social_handles enable row level security;
alter table public.staff enable row level security;
alter table public.tips enable row level security;
alter table public.verification_events enable row level security;
alter table public.zones enable row level security;

create policy staff_read on public.availability_slots as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.background_checks as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.background_checks as permissive for UPDATE to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.bot_sessions as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.categories as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.categories as permissive for ALL to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.wa_events as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.client_addresses as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.clients as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.clients as permissive for UPDATE to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.dispatch_offers as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.disputes as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.disputes as permissive for ALL to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.identity_checks as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.job_events as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.job_photos as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.jobs as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.messages as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.payment_records as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.portfolio_items as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.portfolio_items as permissive for UPDATE to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.pro_categories as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.pro_categories as permissive for UPDATE to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.pro_services as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.pros as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.pros as permissive for UPDATE to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.ratings as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public."references" as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public."references" as permissive for UPDATE to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.requests as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.requests as permissive for UPDATE to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.services as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.services as permissive for ALL to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.settings as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.settings as permissive for ALL to authenticated using (is_staff()) with check (is_staff());
create policy staff_read on public.social_handles as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.staff as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.tips as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.verification_events as permissive for SELECT to authenticated using (is_staff());
create policy staff_read on public.zones as permissive for SELECT to authenticated using (is_staff());
create policy staff_write on public.zones as permissive for ALL to authenticated using (is_staff()) with check (is_staff());
