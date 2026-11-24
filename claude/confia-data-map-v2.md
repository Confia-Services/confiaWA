# Confía — Data map v2 (3NF) · lógica del app

Alineado con CLAUDE.md del 26 oct 2026 (v2.1: canales). Sustituye `confia-pro-data-map.md` (14 sep): esa versión era pre-belleza y no tenía cliente, servicios, franjas, cola ni relay.

Alcance: todo lo que existe en v0 (§5), pro y cliente, ambos sobre WhatsApp. Supabase es la fuente de verdad; los scripts (Edge Functions) no guardan estado.

Reglas de diseño:
- Nada derivado se guarda (rating promedio, trabajos, tiempo de respuesta → vistas).
- Categoría y servicio = configuración. Agregar una vertical es un `INSERT`, nunca código.
- Todo cambio de estado de verificación o de trabajo deja rastro (`verification_events`, `job_events`).
- Cada tabla lleva su clase de dato (Ley 172-13): **público** (lo ve el cliente en el perfil), **interno** (solo equipo/sistema), **sensible** (cédula, antecedentes, dirección, pagos; RLS estricta + borrado por política).
- La pro siempre acepta. No existe ningún camino en el modelo que asigne un trabajo sin `dispatch_offers.response = 'si'` (§7, lección UC).

---

## A. Configuración (público)

### `zones`
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| name | text unique | Naco, Piantini, Gazcue, Bella Vista |
| active | bool | solo Naco–Piantini activas en lanzamiento |

### `categories`
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| slug | text unique | `unas`, `peluqueria`, `barberia`, `maquillaje`, `depilacion`, `masaje` |
| name | text | |
| color | text | hex; la C modular del app lee esto |
| pricing_type | enum | `por_servicio` · `por_hora` · `mensual` · `cotizacion` · `fija_visita` |
| is_urgent | bool | false en belleza; queda para hogar |
| legal_hold | bool | true en depilación/estética y masaje: no se lista hasta revisión del abogado (§4) |
| requires_certificate | bool | false en belleza (INFOTEP es sello opcional) |
| active | bool | apagar sin borrar; hogar entra `active = false` |

### `services`
Lo que el cliente pide. Placeholders hasta la lista definitiva (§10).
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| category_id | uuid FK categories | |
| slug / name | text | `manicure`, `brushing`, `maquillaje_novia` |
| reference_price | numeric null | **provisional** (§6b); anclas de mercado, no precio de Confía |
| duration_min | smallint null | para ordenar la cola; estimación |
| requires_advance_booking | bool | novias = true |
| active | bool | |

---

## B. Personas

### `pros` — público parcial / sensible
| col | tipo | clase | nota |
|---|---|---|---|
| id | uuid PK | | |
| phone | text unique | sensible | E.164; identidad del chat "Confía Pros" |
| cedula | text unique null | sensible | se llena tras KYC |
| first_name / last_name | text | interno | de la JCE |
| display_name | text | público | lo que ve el cliente |
| photo_url | text | público | |
| zone_id | uuid FK zones | público | |
| status | enum | público (solo el sello) | `onboarding` · `pendiente` · `verificada` · `suspendida` · `rechazada` |
| verified_at | timestamptz null | | |
| infotep_verified_at | timestamptz null | público (sello "Certificada") | se verifica por cédula; null ≠ fraude |
| deleted_at | timestamptz null | | soft delete → cron borra sensibles a 30 días |
| created_at / updated_at | | | |

### `clients` — interno / sensible, **nunca público**
| col | tipo | clase | nota |
|---|---|---|---|
| id | uuid PK | | |
| phone | text unique | sensible | identidad del chat "Confía Clientes" |
| first_name | text | interno | único dato que ve la pro (en la plantilla) |
| last_name | text null | interno | |
| status | enum | interno | `activo` · `bloqueado` |
| blocked_reason | text null | interno | |
| created_at | | | |

### `client_addresses` — sensible
Un cliente puede pedir a más de una dirección (su casa, la de su mamá). La pro recibe la dirección del trabajo, nunca el teléfono.
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| client_id | uuid FK clients | |
| zone_id | uuid FK zones | |
| label | text | "Casa" por defecto; "Oficina", "Mamá"… (v2.2) |
| line | text | calle, edificio, apto |
| notes | text null | "torre B, decirle al portero" |
| is_default | bool | |

### `client_identities` — interno (v2.1)
Un cliente, N identidades por canal. El cliente puede escribir por WhatsApp hoy y por Instagram mañana y ser el mismo. Un trigger crea la identidad `whatsapp` desde `clients.phone`.
| col | tipo | nota |
|---|---|---|
| client_id | FK clients | |
| channel | enum | `whatsapp` · `instagram` · `app` |
| external_id | text | teléfono E.164 · ID de usuario de IG · `auth.users.id` |
| | | PK (channel, external_id); UNIQUE (client_id, channel) |

### `staff` — interno
| col | tipo | nota |
|---|---|---|
| id | uuid PK = auth.users.id | |
| name, role | text, enum `admin` · `verificador` · `soporte` | |

---

## C. Verificación de la pro (sensible salvo donde se indica)

### `pro_categories`
| col | tipo | nota |
|---|---|---|
| pro_id, category_id | PK compuesta, FKs | |
| status | enum | `pendiente` · `verificada` · `rechazada` |
| verified_at | timestamptz null | |

### `pro_services` — público
Qué servicios ofrece. `price` existe pero vive como **provisional** hasta cerrar §6b (quién fija precio).
| col | tipo | nota |
|---|---|---|
| pro_id, service_id | PK compuesta, FKs | service.category_id debe estar en `pro_categories` (check) |
| price | numeric null | null hasta decisión §6b |
| active | bool | |

### `identity_checks` (KYC)
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| pro_id | FK pros | |
| provider | enum | `didit` · `verifik` |
| provider_session_id | text unique | referencia externa; **no** se guarda el payload biométrico |
| cedula_match / face_match / liveness | bool | tres cosas distintas (§5b) |
| result | enum | `aprobado` · `rechazado` · `revision` |
| checked_at | timestamptz | |

### `background_checks` (PGR)
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| pro_id | FK pros | |
| pgr_code | text unique | código de validación; **no** el CAS de pago |
| doc_url | text null | PDF en bucket privado; se borra al confirmar si la política lo permite (Art. 77) |
| issued_at | date | fecha de emisión que trae el certificado |
| result | enum | `sin_antecedentes` · `con_antecedentes` · `no_verificable` |
| verified_by / verified_at | FK staff, timestamptz | confirmación manual en portal PGR |
| valid_until | date | `issued_at + max_age_days` (propuesta 90; parámetro en `settings`) |

### `references`
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| pro_id | FK pros | |
| name, phone | text | |
| relationship | enum | `clienta` · `salon` · `colega` · `otro` |
| status | enum | `pendiente` · `verificada` · `no_contesto` · `negativa` |
| called_by / called_at | FK staff, timestamptz | |
| recommends | bool null | |
| notes | text | |

### `portfolio_items` — público (si `status = aprobada`)
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| pro_id, category_id | FK pro_categories | la foto es de uñas, no de Ana |
| url | text | bucket público solo tras aprobación |
| has_face | bool | |
| consent_confirmed | bool | obligatorio si `has_face` (regla pendiente §10) |
| status | enum | `pendiente` · `aprobada` · `rechazada` |
| reviewed_by / reviewed_at | | |

### `social_handles` — interno, nunca público
| col | tipo | nota |
|---|---|---|
| pro_id, network | PK compuesta; enum `instagram` · `tiktok` · `facebook` | |
| handle | text | |
| reviewed_at, reviewer_notes | | |

### `verification_events` — interno (audit)
| col | tipo | nota |
|---|---|---|
| id | bigint PK | |
| pro_id | FK pros | |
| entity | enum | `pro` · `pro_category` · `identity` · `background` · `reference` · `portfolio` · `infotep` |
| entity_id | uuid | |
| from_status / to_status | text | |
| actor_id | FK staff null | null = sistema |
| note, created_at | | |

**Regla de transición a `verificada` (trigger):**
```
EXISTS identity_checks result='aprobado'
AND EXISTS background_checks result='sin_antecedentes' AND valid_until > today
AND count(references status='verificada' AND recommends) >= 2
AND count(portfolio_items status='aprobada') >= settings.portfolio_min
AND EXISTS pro_categories status='verificada'
```
Sin sello no entra en `dispatch_offers`.

---

## D. Disponibilidad (interno)

### `availability_slots`
La pro dice sus franjas libres cada mañana al bot, o al recibir una solicitud.
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| pro_id | FK pros | |
| date | date | |
| slot | enum | `manana` · `tarde` · `noche` |
| source | enum | `diaria` · `al_pedido` |
| created_at | | |
| | | UNIQUE (pro_id, date, slot) |

---

## E. Solicitud → despacho → trabajo

### `requests` — interno (dirección: sensible)
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| client_id | FK clients | |
| service_id | FK services | |
| address_id | FK client_addresses | la zona sale de aquí |
| requested_date | date | |
| requested_slot | enum | `manana` · `tarde` · `noche` |
| notes | text null | texto libre del cliente; el bot lo transmite, no lo interpreta |
| channel | enum | `whatsapp` · `instagram` · `app` — por dónde pidió; el relay le responde ahí (v2.1) |
| status | enum | `abierta` · `despachando` · `asignada` · `sin_oferta` · `cancelada` |
| origin | enum | `frio` · `red_personal` — la señal real (§9.3); lo marca el equipo |
| preferred_pro_id | FK pros null | "quiero con Ana" — va primera en el despacho (v2.2) |
| created_at | | |

### `dispatch_offers` — interno
Una fila por intento. Es la prueba de que la pro aceptó.
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| request_id | FK requests | |
| pro_id | FK pros | |
| rank | smallint | orden de despacho (rating desc, respuesta asc) |
| wave | enum | `libre` · `con_cola` · `manual` |
| sent_at | timestamptz | → tiempo de respuesta |
| expires_at | timestamptz | |
| response | enum null | `si` · `no` · `sin_respuesta` · `invalida` |
| responded_at | timestamptz null | |
| raw_reply | text null | lo que escribió ("dale", "voy") |
| client_response | enum null | `si` · `otra` · `sin_respuesta` — veto del cliente sobre la tarjeta (v2.2) |
| client_responded_at / client_expires_at | timestamptz | |
| | | UNIQUE (request_id, pro_id) |

### `jobs` — interno
Nace solo cuando una `dispatch_offer` tiene `response = 'si'` **y** `client_response = 'si'` (v2.2: la pro acepta, el cliente confirma la tarjeta).
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| request_id | FK requests unique | 1:1 |
| pro_id | FK pros | |
| offer_id | FK dispatch_offers unique | la aceptación que lo creó |
| status | enum | ver máquina de estados |
| scheduled_at | timestamptz null | hora exacta acordada por el relay |
| agreed_price | numeric null | lo que acordaron; **provisional** hasta §6b |
| completed_at | timestamptz null | pro manda `listo` |
| closed_at | timestamptz null | cliente califica o 24 h |
| guarantee_until | date null | closed_at + 7 días |
| cancelled_by / cancel_reason | enum `pro` · `cliente` · `confia`, text | |

**Máquina de estados `jobs.status`:**
```
aceptado ──(hay otro activo)──▶ en_cola ──(se libera)──▶ aceptado
aceptado ──▶ activo ──(listo + ≥1 foto)──▶ esperando_cliente ──(rating | 24h)──▶ cerrado
cualquiera ──▶ cancelado
cerrado ──(dentro de garantía)──▶ en_disputa ──▶ cerrado
```
Constraints: máx. 1 job `activo`/`aceptado` por pro; máx. 2 `en_cola` por pro. Trigger: al pasar a `cerrado` o `cancelado`, el `en_cola` más antiguo pasa a `aceptado` y el bot avisa.

### `job_events` — interno (audit)
| col | tipo | nota |
|---|---|---|
| id, job_id | bigint PK, FK | |
| from_status / to_status | | |
| actor | enum | `pro` · `cliente` · `sistema` · `staff` |
| note, created_at | | "voy tarde, 4pm" queda aquí |

### `job_photos` — interno (cierre); público solo si la pro la pasa al portafolio
| col | tipo | nota |
|---|---|---|
| id, job_id | uuid PK, FK | |
| url | text | bucket privado |
| uploaded_at | | |

### `ratings`
| col | tipo | clase | nota |
|---|---|---|---|
| id | uuid PK | | |
| job_id | FK jobs | | |
| direction | enum | | `cliente_a_pro` (público, agregado) · `pro_a_cliente` (interno, nunca público) |
| score | smallint 1–5 | | |
| comment | text null | | |
| created_at | | | UNIQUE (job_id, direction) |

### `payment_records` — sensible, interno
Lo que la pro reporta del pago. Confía no procesa dinero.
| col | tipo | nota |
|---|---|---|
| job_id | FK jobs PK | |
| status | enum | `pago` · `tardo` · `no_pago` |
| noted_at | | |

### `tips` — interno
Propina sugerida y registrada, no procesada (§5).
| col | tipo | nota |
|---|---|---|
| job_id | FK jobs PK | |
| amount | numeric | |
| declared_at | | el cliente dice que la hizo por transferencia |

### `disputes` — interno
| col | tipo | nota |
|---|---|---|
| id, job_id | uuid PK, FK | |
| opened_by | enum `cliente` · `pro` | |
| reason | text | |
| status | enum | `abierta` · `resuelta_cliente` · `resuelta_pro` · `cerrada` |
| handled_by / resolved_at | FK staff, timestamptz | verificamos resultado, no supervisamos (§7) |

---

## F. Mensajería (interno; cuerpo de mensajes = dato personal)

Multicanal por diseño (v2.1): nada aquí asume que la identidad es un teléfono. v0 enciende solo `whatsapp`; las pros son solo WhatsApp en v0.

### `channel_events` — crudo, idempotente
| col | tipo | nota |
|---|---|---|
| external_message_id | text PK | dedupe del webhook |
| channel | enum | `whatsapp` · `instagram` · `app` |
| line | enum | `pros` · `clientes` (qué cuenta lo recibió) |
| sender_id | text | teléfono, ID de IG o user id |
| payload | jsonb | tal cual Meta |
| received_at | | |
| processed_at | timestamptz null | el script marca cuando terminó |

### `bot_sessions` — estado de conversación (los scripts no guardan estado)
| col | tipo | nota |
|---|---|---|
| channel, line, external_id | PK compuesta | |
| party_type / party_id | enum `pro` · `cliente` · `desconocido`, uuid null | |
| state | text | `onboarding.cedula`, `onboarding.referencias`, `idle`, `relay`, `cierre.rating`… |
| context | jsonb | lo mínimo para el paso actual; se vacía al terminar |
| updated_at | | |

### `messages` — el relay
| col | tipo | nota |
|---|---|---|
| id | uuid PK | |
| job_id | FK jobs | todo mensaje del relay cuelga de un job |
| direction | enum | `pro_a_cliente` · `cliente_a_pro` · `bot_a_pro` · `bot_a_cliente` |
| type | enum | `text` · `audio` · `image` · `location` · `template` |
| body | text null | |
| media_url | text null | |
| external_in_id / external_out_id | text | id del mensaje recibido y del reenviado, en el canal que sea |
| blocked_reason | enum null | `telefono` · `llamada` · `en_cola` · `fuera_de_job` — si no es null, no se reenvió |
| created_at | | |

### `settings` — configuración operativa
| key | value | ejemplos |
|---|---|---|
| text PK | jsonb | `pgr_max_age_days: 90`, `portfolio_min: 5`, `queue_max: 2`, `client_close_hours: 24`, `guarantee_days: 7`, `offer_ttl_min` |

---

## G. Relaciones

```
zones 1─N client_addresses · zones 1─N pros
categories 1─N services · categories 1─N pro_categories N─1 pros
services 1─N pro_services N─1 pros
pros 1─N identity_checks · background_checks · references · social_handles · verification_events · availability_slots
pro_categories 1─N portfolio_items
clients 1─N client_addresses · clients 1─N client_identities · clients 1─N requests
requests N─1 services · requests N─1 client_addresses
requests 1─N dispatch_offers N─1 pros
dispatch_offers 1─1 jobs · requests 1─1 jobs · pros 1─N jobs
jobs 1─N job_events · job_photos · messages · ratings(≤2)
jobs 1─1 payment_records · tips · disputes(0..1)
staff 1─N (background_checks, references, portfolio_items, disputes, verification_events)
```

---

## H. Vistas (derivadas, nunca columnas)

- `pro_public_profile` — lo único que el cliente ve: display_name, photo, zone, sello, `infotep`, avg_rating, rating_count, jobs_closed, median_response_min, portafolio aprobado, servicios activos. **No expone** phone, cédula, nombre legal, redes.
- `pro_stats` — por pro: jobs_closed, avg_rating, rating_count, median_response_min (de `dispatch_offers`), acceptance_rate, repeat_clients.
- `client_stats` — por cliente, interno: avg_rating_by_pros, no_pago_count, jobs_closed. Alimenta despacho y bloqueo.
- `verification_checklist` — qué le falta a cada pro para el sello.
- `dispatch_candidates(request_id)` — pros verificadas, con `pro_services` activo para el servicio, zona compatible, franja libre, sin job activo; ordenadas por rating desc y respuesta asc. Segunda ola: con cola < `queue_max`.
- `pro_card` — la tarjeta que ve el cliente: foto, sello, rating, 3 fotos del portafolio.
- `pro_recent_quality` — promedio de las últimas N calificaciones por pro; alimenta `cron_quality_suspend`.
- `qc_due` — trabajos cerrados de pros nuevas pendientes de llamada de QC.
- `signals` — trabajos `origin = frio` por semana, clientes repetidos, pros verificadas, pros que dijeron que pagarían. Las tres métricas del gate.

## I. Crons (pg_cron)

- Cada hora: `jobs` en `esperando_cliente` > `client_close_hours` → `cerrado`.
- Cada hora: `dispatch_offers` vencidas sin respuesta → `sin_respuesta`, y seguir con el siguiente rank.
- Diario: `pro_recent_quality.recent_avg` < `quality_min_rating` con ventana completa → pro `suspendida`.
- Diario: `background_checks.valid_until` < hoy → pro a `pendiente` + aviso.
- Diario: pros con `deleted_at` + 30 días → borrar `identity_checks`, `background_checks`, `references`, `social_handles`, archivos privados; conservar `jobs`/`ratings` anonimizados.
- Diario: `messages` y `channel_events` más viejos que la política de retención (por fijar con el abogado) → borrar cuerpo y media, conservar metadatos.
- Diario 7:00: disparar plantilla "¿franjas de hoy?" a pros verificadas sin `availability_slots` para hoy.

## J. RLS (resumen)

- v0: la única escritora es la service role de los scripts (Edge Functions). Pros y clientes no tocan Supabase directo (todo pasa por WhatsApp). Staff lee todo; escribe solo verificación y disputas.
- Cuando llegue el app del cliente (v1): el cliente lee `pro_public_profile`, sus `requests`, sus `jobs` y sus `ratings cliente_a_pro`. Nunca `ratings pro_a_cliente`, `payment_records` ni `client_stats`.
- Storage: privados `kyc/`, `pgr/`, `job-photos/`; público `portfolio/` (solo aprobadas).

## K. Abierto (depende de decisiones del CLAUDE.md)

- `services`: placeholders hasta la lista definitiva de Javi.
- `pro_services.price` y `jobs.agreed_price`: forma final tras §6b. Si Confía fija tabla, `price` sale de `pro_services` y entra en `services`.
- `settings.pgr_max_age_days` (90 propuesto) y `portfolio_min` (sin decidir).
- `portfolio_items.consent_confirmed`: regla de rostro pendiente.
- Retención de `messages`: plazo para el abogado.
- Campo de alergias del cliente: **no está en el modelo** a propósito (dato de salud, Art. 6). Entra solo con respuesta del abogado.
- "Un solo número" (Franco) vs dos: el modelo soporta ambos (`channel_events.line`), pero el relay asume dos.
- Instagram y app como canales del cliente: el modelo ya los soporta (`client_identities`, `requests.channel`); se encienden por decisión escrita en CLAUDE.md, no antes.
