-- Confía · seed. Regenerated 2026-11-13 from confia-prod (ref mymhxetdaabalragmyso):
-- SELECT over zones, categories, services and settings, emitted as idempotent INSERTs.
-- Prices are provisional (CLAUDE.md §6b). Categories with active = false are the home-services map, not launch.

-- zones (4)
insert into public.zones (id, name, active) values ('f9a10a9b-36cd-4f98-b238-d2c515623c58', 'Bella Vista', 'f') on conflict (id) do nothing;
insert into public.zones (id, name, active) values ('6d0ded8c-4145-4b8f-be10-123f4806eefd', 'Gazcue', 'f') on conflict (id) do nothing;
insert into public.zones (id, name, active) values ('21053102-d6ed-428c-a567-1f73eac07130', 'Naco', 't') on conflict (id) do nothing;
insert into public.zones (id, name, active) values ('15051504-b1fb-4f7d-8717-997b4f4142d6', 'Piantini', 't') on conflict (id) do nothing;

-- categories (10)
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('cd9b3313-d11b-46cf-8dd3-1e2c21a06c08', 'barberia', 'Barbería', '#3F51B5', 'por_servicio', 'f', 'f', 'f', 't') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('26a197b1-a0d4-4025-9c12-d9298bf6f68b', 'depilacion', 'Depilación, estética, cejas y pestañas', '#009688', 'por_servicio', 'f', 't', 'f', 'f') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('4589e3e2-a339-47c3-bf53-72731ddf18e9', 'ebanisteria', 'Ebanistería', '#8D6E63', 'cotizacion', 'f', 'f', 'f', 'f') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('b5529f64-a952-4dc4-82dd-090b6f4bec49', 'electricidad', 'Electricidad', '#FFC107', 'fija_visita', 't', 'f', 'f', 'f') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('be152328-ab5a-48f1-86cf-20aa78a27670', 'limpieza', 'Limpieza', '#4CAF50', 'por_hora', 'f', 'f', 'f', 'f') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('ce3c6125-9a68-40f5-bcf8-7b6b46e5aa69', 'maquillaje', 'Maquillaje', '#FF5722', 'por_servicio', 'f', 'f', 'f', 't') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('0b5addf4-0ad0-4af5-bee3-12623d325ded', 'masaje', 'Masaje', '#795548', 'por_servicio', 'f', 't', 'f', 'f') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('f06be4d3-2795-4ba6-a4ba-7615e0fa1e2f', 'peluqueria', 'Peluquería', '#9C27B0', 'por_servicio', 'f', 'f', 'f', 't') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('e4e43f64-d0ff-4216-9fa2-372bfa65ac30', 'plomeria', 'Plomería', '#2196F3', 'fija_visita', 't', 'f', 'f', 'f') on conflict (id) do nothing;
insert into public.categories (id, slug, name, color, pricing_type, is_urgent, legal_hold, requires_certificate, active) values ('79455e90-d7e7-4d3b-b7ff-0ee8ed0b81dc', 'unas', 'Uñas', '#E91E63', 'por_servicio', 'f', 'f', 'f', 't') on conflict (id) do nothing;

-- services (17)
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('70621604-f69f-4710-8135-90f193f8d87e', 'cd9b3313-d11b-46cf-8dd3-1e2c21a06c08', 'barba', 'Barba', '400.00', '25', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('740c6315-1ca5-4c70-8ee9-80da0e2b18b5', 'cd9b3313-d11b-46cf-8dd3-1e2c21a06c08', 'corte_barba', 'Corte + barba', '800.00', '50', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('35884c3c-1889-49ff-8b09-137845ad9437', 'cd9b3313-d11b-46cf-8dd3-1e2c21a06c08', 'corte_barberia', 'Corte', '600.00', '40', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('d644af15-fcfd-4b41-9d05-8a2fcb577775', 'ce3c6125-9a68-40f5-bcf8-7b6b46e5aa69', 'maquillaje_novia', 'Maquillaje de novia (con prueba)', '5000.00', '120', 't', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('fb55234e-531a-4d39-bea2-3d4841c8d29c', 'ce3c6125-9a68-40f5-bcf8-7b6b46e5aa69', 'maquillaje_social', 'Maquillaje social', '2000.00', '60', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('d95018f1-85cd-4567-a248-4af5c03f9608', 'f06be4d3-2795-4ba6-a4ba-7615e0fa1e2f', 'brushing', 'Brushing', '1100.00', '60', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('f63abd52-9868-403d-9826-537d8c276d43', 'f06be4d3-2795-4ba6-a4ba-7615e0fa1e2f', 'color', 'Color / tinte', NULL, '120', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('47689c14-b791-4b9e-86d5-2aa0b36670c6', 'f06be4d3-2795-4ba6-a4ba-7615e0fa1e2f', 'corte', 'Corte', '1000.00', '45', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('1f7741f3-c282-4e51-93ef-4c0d49bd556a', 'f06be4d3-2795-4ba6-a4ba-7615e0fa1e2f', 'keratina', 'Keratina / alisado', NULL, '150', 't', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('d500b6ac-ee0a-4b28-a056-8dc628a9345f', 'f06be4d3-2795-4ba6-a4ba-7615e0fa1e2f', 'lavado_brushing', 'Lavado + brushing', '1300.00', '75', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('2fc684e5-f06d-44ca-b845-00def0f663de', 'f06be4d3-2795-4ba6-a4ba-7615e0fa1e2f', 'peinado_evento', 'Peinado de evento', '1800.00', '75', 't', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('41797859-5760-40cb-aaa1-e760297d0218', 'f06be4d3-2795-4ba6-a4ba-7615e0fa1e2f', 'rizos', 'Rizos (definición / tratamiento)', '1500.00', '90', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('53e389bb-2fff-4079-8901-1af1be4899f1', '79455e90-d7e7-4d3b-b7ff-0ee8ed0b81dc', 'gel', 'Uñas en gel / acrílico', '1500.00', '90', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('e2adf9a8-43a4-4fd7-bfe0-c11006c4d688', '79455e90-d7e7-4d3b-b7ff-0ee8ed0b81dc', 'manicure', 'Manicure', '700.00', '60', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('8f8b7725-b860-4b71-bcc2-d9d9eff7ec61', '79455e90-d7e7-4d3b-b7ff-0ee8ed0b81dc', 'manicure_pedicure', 'Manicure + pedicure', '1400.00', '110', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('7691d3d1-9310-4c6e-b52d-adb84bbf3a6e', '79455e90-d7e7-4d3b-b7ff-0ee8ed0b81dc', 'pedicure', 'Pedicure', '800.00', '60', 'f', 't') on conflict (id) do nothing;
insert into public.services (id, category_id, slug, name, reference_price, duration_min, requires_advance_booking, active) values ('523a24aa-70fb-4271-86f7-1e13747a7f7b', '79455e90-d7e7-4d3b-b7ff-0ee8ed0b81dc', 'retiro', 'Retiro de gel / acrílico', '400.00', '30', 'f', 't') on conflict (id) do nothing;

-- settings (18)
insert into public.settings (key, value, note) values ('client_close_hours', '24'::jsonb, 'CLAUDE.md §5') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('dispatch_future_alt_min', '240'::jsonb, 'future-date: offer alternatives after N min') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('dispatch_future_escalate_at', '"20:00"'::jsonb, 'future-date: escalate the evening before at this local time if still unassigned') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('dispatch_future_update_min', '60'::jsonb, 'future-date request: update after N min') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('dispatch_sameday_alt_min', '45'::jsonb, 'same-day: offer alternative slots (where a pro is free) after N min') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('dispatch_sameday_escalate_min', '60'::jsonb, 'same-day: hand to the team after N min') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('dispatch_sameday_update_min', '15'::jsonb, 'same-day request: "seguimos buscando" after N min without a pro') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('guarantee_days', '7'::jsonb, 'CLAUDE.md §5') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('message_retention_days', '180'::jsonb, 'pending lawyer (Ley 172-13)') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('offer_ttl_min', '30'::jsonb, 'how long a dispatch offer waits for sí/no — provisional') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('pgr_max_age_days', '90'::jsonb, 'proposed, not decided (§10). Mirrors the generated column in background_checks.') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('portfolio_min', '3'::jsonb, 'proposed, not decided (§10)') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('qc_first_jobs', '3'::jsonb, 'team calls the client after each of the first N jobs of a new pro') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('quality_min_rating', '4.2'::jsonb, 'auto-suspend below this over the last quality_window closed jobs — provisional') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('quality_window', '5'::jsonb, 'number of recent rated jobs considered') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('queue_max', '2'::jsonb, 'CLAUDE.md §5') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('sameday_cutoff_noche', '"17:00"'::jsonb, 'last time to request same-day evening slot') on conflict (key) do nothing;
insert into public.settings (key, value, note) values ('sameday_cutoff_tarde', '"14:00"'::jsonb, 'last time to request same-day afternoon slot') on conflict (key) do nothing;
