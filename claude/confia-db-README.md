# Confía · base de datos v0

Schema Supabase del data map v2.1 (`claude/confia-data-map-v2.md`). 30 tablas, 8 vistas, 18 migraciones. **Aplicado en `confia-prod` el 26 oct 2026 (0001–0018 + seed).** Probado end-to-end contra Postgres 16.

## Estructura

```
supabase/
  migrations/
    0001_extensions_enums.sql   enums + helpers (setting_int)
    0002_config.sql             settings · zones · categories · services
    0003_people.sql             staff · pros · clients · client_addresses
    0004_verification.sql       KYC · PGR · referencias · portafolio · redes · audit · GATE del sello
    0005_availability.sql       franjas
    0006_transactions.sql       requests · dispatch_offers · jobs · cola · cierre · ratings · disputas
    0007_messaging.sql          wa_events · bot_sessions · messages · relay guard
    0008_views_functions.sql    pro_stats · pro_public_profile · client_stats · checklist · dispatch_candidates · signals
    0009_rls.sql                RLS (service role escribe; staff lee)
    0010_cron.sql               cierres a 24 h · ofertas vencidas · PGR vencido · borrado 172-13
    0011_services_v1.sql        lista definitiva de servicios (26 oct)
    0012_channels.sql           multicanal: client_identities · requests.channel · channel_events · bot_sessions por (channel, line, external_id)
    0013_client_confirm_quality.sql  veto del cliente (tarjeta) · pedir por nombre · calidad: qc_due · cron_quality_suspend
    0014_addresses_dispatch_timing.sql  etiqueta de dirección ("Casa") · tiempos de despacho mismo día / otro día · alternative_slots()
    0015_enable_pg_cron.sql     activa pg_cron y programa los 6 crons (solo Supabase)
    0016_security_hardening.sql vistas security_invoker · anon sin acceso a nada · search_path fijo
    0017_revoke_public_execute.sql  funciones solo para service_role (+ is_staff para authenticated)
    0018_storage_buckets.sql    buckets kyc · pgr · job-photos (privados) · portfolio (público), 10 MB, solo imágenes/PDF
  seed.sql                      zonas, categorías, servicios definitivos (26 oct), settings
  tests/
    smoke.sql                   ciclo completo: onboarding → sello → solicitud → sí → job → relay → cola → cierre → disputa
    run_local.sh                corre todo en un Postgres local (stub de auth)
```

## Aplicar en Supabase

Ya está aplicado en `confia-prod` (ref `mymhxetdaabalragmyso`). Para migraciones nuevas:

```bash
supabase link --project-ref mymhxetdaabalragmyso
supabase db push          # aplica solo las migrations/ que falten
```

La tabla `supabase_migrations.schema_migrations` lleva el registro; no re-aplicar a mano.

Buckets ya creados (0018). Falta solo: crear el primer usuario staff en Auth y hacer `insert into staff`.

## Reglas que la base de datos hace cumplir sola

| Regla | Dónde |
|---|---|
| `pros.status = 'verificada'` solo con KYC + PGR vigente + 2 referencias + N fotos + 1 categoría | `trg_pro_status_gate` |
| Un job nace solo de una `dispatch_offer` con `response = 'si'` **y** `client_response = 'si'` | `trg_job_insert` |
| Promedio de las últimas 5 calificaciones < 4.2 → pro `suspendida` | `cron_quality_suspend` |
| Máx. 1 chat abierto por pro; máx. `queue_max` en cola; el siguiente sube solo al cerrar | índice parcial + `trg_job_status_after` |
| `listo` exige ≥1 foto; cliente califica → cerrado; garantía = cierre + 7 días | `trg_job_status`, `trg_rating_closes` |
| Disputa solo dentro de garantía | `trg_job_status` |
| Teléfonos y pedidos de llamada bloqueados en el relay | `relay_block_reason()` |
| Pro solo ofrece servicios de categorías en las que está inscrita | `check_pro_service_category` |
| Foto con rostro ⇒ consentimiento | check en `portfolio_items` |
| Todo cambio de verificación y de job queda en `*_events` | triggers |
| 30 días tras baja se borran cédula, KYC, PGR, referencias, redes | `cron_purge_deleted_pros` |

## Lo que los scripts llaman

Los scripts (Supabase Edge Functions, `functions/`) son pegamento entre el webhook de WhatsApp y estas funciones/vistas. No guardan estado ni reglas de negocio: si falta una regla, es migración.

- `dispatch_candidates(request_id)` → lista ordenada; el script inserta una `dispatch_offer` por turno.
- `answer_offer(offer_id, texto)` → parsea sí/no/variantes de la pro; devuelve `si` · `no` · `invalida`.
- `pro_card` (vista) → lo que va en la tarjeta al cliente: foto, sello, rating, 3 fotos.
- `answer_offer_client(offer_id, texto)` → `si` · `otra` · null (re-preguntar). Con `otra`, el script sigue el despacho y avisa a la pro "no se concretó".
- `requests.preferred_pro_id` → pedir por nombre; `dispatch_candidates` la pone primera si cumple.
- `qc_due` (vista) → trabajos cerrados de pros nuevas pendientes de llamada de QC.
- `request_is_sameday(request_id)` y `settings.dispatch_*` → qué tiempos aplicar en la espera.
- `alternative_slots(request_id)` → franjas de los próximos 3 días con alguna pro libre, para ofrecer cuando nadie acepta.
- `resolve_job_for_message(channel, line, external_id)` → a qué job va un mensaje entrante y si debe bloquearse.
- `relay_block_reason(texto)` → `telefono` · `llamada` · null.
- `verification_checklist` → qué le falta a la pro (mensaje de checklist).
- `bot_sessions` → estado del paso actual por (canal, línea, identidad).

## Provisional / abierto (igual que en CLAUDE.md §10)

- `services.reference_price`: provisional hasta §6b (inclinación: banda ±20% sobre la referencia).
- `pro_services.price`, `jobs.agreed_price`: null hasta §6b.
- `settings.portfolio_min` (3) y `pgr_max_age_days` (90, columna generada en `background_checks`): propuestos.
- Retención de `messages` (180 días): para el abogado.
- Sin campo de alergias a propósito (Art. 6).
- Canales: solo `whatsapp` activo en v0. `instagram` y `app` existen en el enum para no migrar después; se encienden por decisión escrita en CLAUDE.md.
