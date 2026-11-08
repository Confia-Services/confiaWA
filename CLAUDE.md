# CLAUDE.md — Confía

> Marketplace de servicios a domicilio en Santo Domingo, construido sobre confianza y verificación de identidad. **Primera área: belleza a domicilio.**
> Nombre comercial registrado: **Confía Services** (ONAPI, Clase 35). Tagline de trabajo: *"Gente de confianza para tu hogar."* — en revisión: no vende belleza; pendiente nuevo tagline.
> Fundadores: Javi (producto y desarrollo) y Victor (operaciones, verificación, marca). Todo se documenta y se comparte entre ambos.

---

## 1. Tesis

Confía **no vende mano de obra**. Vende que, si algo sale mal, hay un nombre, una cédula y una reputación en juego.
El producto es la capa de confianza y descubrimiento. La conversación y el pago viven en WhatsApp.

Dos mensajes, dos audiencias — no mezclar en la misma pantalla:
- **Al cliente:** una profesional con nombre, cédula, portafolio y reputación, que llega a tu casa a la hora acordada y con garantía. Sin sorpresas.
- **A la pro:** estar "verificada" es un ascenso de mercado — acceso a clientas que pagan bien y que no alcanza por su red — y **seguridad**: Confía sabe a qué casa va, con quién, y el cliente también está registrado y calificado.

**Nota de belleza:** en belleza el riesgo grande es de la *pro* (entrar sola a casa de un desconocido), no del cliente. Por eso el cliente se registra (nombre, teléfono, dirección) y las pros lo califican. El sello verificado sigue siendo el producto, pero el mensaje cambia de "te protegemos del extraño" a "las dos partes tienen cara y nombre".

No competimos en precio. El informal siempre será más barato.

## 2. Estado actual (sep 2026)

- **Decisión 14–15 sep 2026: Confía arranca con una sola área, belleza a domicilio.** La marca sigue siendo Confía; belleza es un área, no un nombre nuevo. Branding modular para el app: una **C** que cambia de color por tipo de trabajo (el color es un campo de la categoría). Plomería, electricidad y el resto de categorías del hogar quedan fuera del lanzamiento hasta decisión escrita aquí. Razón del cambio: pendiente de registrar. Pendiente de revisión con Victor.
- **Fase:** construcción del flujo WhatsApp-first para belleza. La fase concierge/gate quedó atrás; el aprendizaje de esa fase alimenta este documento.
- **Lanzamiento esperado:** invierno 2026-27. Las fechas son horizontes, no compromisos con consecuencias.
- **Operación paralela:** WhatsApp Business sigue siendo el canal de matching manual mientras el app no existe. Datos en Google Sheets (PROS, SOLICITUDES, TRABAJOS) — ese esquema es la semilla del modelo de datos.
- **Zona inicial:** Naco–Piantini. Expansión de zona solo con densidad de oferta probada.
- **Señales que seguimos midiendo aunque no haya gate:** trabajos de origen frío (no red personal), clientes repetidos, y pros dispuestos a pagar.

## 3. Cliente y mercado

- **Cliente inicial:** hogares de clase media-alta en Santo Domingo (Piantini, Naco, Gazcue, Bella Vista). Pagan prima por verificación y son los más expuestos al riesgo de contratar informal.
- **Pendiente de validar:** quién decide la contratación en el hogar (dueño, administración del condominio, persona de servicio). Cambia el flujo de reserva.
- **Competidores mapeados:** dbarrio, DDTeAyuda, unamano.do, MANO (lista de espera). Ninguno hace verificación seria.
- **Comparables de modelo:** Booksy (membresía/lead fee del lado del pro) y Urban Company (ambición a largo plazo: UC de LATAM).

## 4. Categorías

### Belleza a domicilio (lanzamiento) — placeholders hasta que Javi entregue la lista definitiva

| Categoría | Precio | Nota |
|---|---|---|
| Uñas (manicure, pedicure, gel) | Por servicio — pendiente | Contacto dérmico: higiene y esterilización del equipo que se lleva a domicilio. |
| Peluquería (corte, brushing, color, keratina) | Por servicio — pendiente | Mayor ticket; el portafolio pesa más aquí. |
| Barbería | Por servicio — pendiente | Abre el segmento masculino. |
| Maquillaje (social, novias) | Por servicio — pendiente | Novias = ticket más alto y reserva anticipada. |
| Depilación y estética | Por servicio — pendiente | ⚠️ Flag MSP por contacto dérmico. Revisar con abogado antes de listar. |
| Masaje | Por servicio — pendiente | ⚠️ Flag legal. Revisar antes de listar. |

**Licencias (investigado 15 sep 2026):** no existe licencia individual para ejercer belleza en RD; la habilitación sanitaria del MSP es del establecimiento, no de la persona. Lo verificable es el **certificado INFOTEP** (formación o validación ocupacional; se consulta en línea por cédula). Fuente principal: blog de un software de salones, no el MSP — entra en la consulta con el abogado.

### Servicios para el hogar (fuera del lanzamiento — se conservan como mapa)

| Grupo | Categorías | Modelo | Nota |
|---|---|---|---|
| Urgentes ("HOY MISMO") | Plomería, Electricidad | Precio fijo por visita | Antes candidatas al lanzamiento. Menor barrera de confianza, dolor inmediato, difícil de desintermediar. |
| Urgentes — en revisión | Mecánica | Precio fijo | No es "para tu hogar"; el trabajo ocurre fuera de casa. Decidir si entra al lanzamiento o se justifica aparte. |
| Recurrentes alta confianza | Niñeras, Cocina, Limpieza | Por hora / mensual | Segunda ola. Solo cuando "verificado" ya pese. Mayor riesgo de desintermediación. |
| Recurrentes — en revisión legal | Portería y seguridad | Mensual | Ley de seguridad privada y licencias en DR. No listar sin revisión de abogado. |
| Cotización, ticket alto | Ebanistería | Cotización gratis a domicilio | Monetización por lead/listing, no por comisión. Ticket alto (RD$300k+), desintermediación máxima. |

**Excluido:** Albañilería. Cultura estructural de informalidad, verificar cuadrillas completas mata la oferta, riesgo legal y operativo máximo. Si vuelve, solo con modelo *maestro constructor* y desde posición de marca fuerte.

**Regla de arquitectura:** categoría = configuración, no código. Agregar o quitar una vertical debe ser un cambio de datos (nombre, tipo de precio, campos de verificación, flag urgente), no un rebuild.

## 5. Alcance del producto

### v0 (lo que se construye ahora)

**Lado del pro: 100% WhatsApp. No hay app del pro en v0.** Registro, verificación, solicitudes, coordinación con el cliente y cierre del trabajo ocurren en un solo chat con el número "Confía Pros". El app del pro (dashboard, agenda) es v1.

**Lado del cliente:** app/PWA con perfiles verificados, ratings, precios por categoría y solicitud de reserva. El cliente conversa con el pro a través del número "Confía Clientes". Se diseña en su propia área.

Lo que existe en v0, sin importar el lado:
- Perfiles verificados de pros: cédula (KYC automático contra JCE) + no antecedentes (PGR, código validado) + 2 referencias llamadas + **portafolio obligatorio** (fotos de trabajos que la pro sube y autoriza; se muestran en una galería pública de su perfil). Certificado INFOTEP como sello opcional "Certificada", verificable por cédula. Redes sociales de la pro: solo para revisión interna, nunca públicas. Sello "verificado" visible.
- **Registro del cliente obligatorio:** nombre, teléfono y dirección. Las pros califican al cliente (1–5 + comentario) y se registra el comportamiento de pago (pagó / tardó / no pagó). Uso interno para despacho y bloqueo; nunca público.
- Ratings y reseñas. Precios transparentes por categoría.
- **Relay de conversaciones:** el pro y el cliente nunca ven el número del otro. Confía tiene dos números; cada mensaje se reenvía al otro lado con el nombre del remitente. Todo queda registrado.
- **Cierre mutuo:** el pro manda fotos del trabajo terminado (mínimo 1) → el cliente califica y puede dejar propina → si no responde en 24 h se cierra igual. Garantía 7 días desde el cierre.
- **Matching por disponibilidad:** el cliente pide servicio + franja (hoy tarde, mañana mañana, fecha); la pro indica sus franjas libres (cada mañana al bot, o al recibir una solicitud); se despacha uno a uno a las que encajan. No hay "HOY MISMO" con ventana de 10 min: belleza es cita a hora acordada.
- **Cola secuencial por pro:** un solo chat abierto a la vez; trabajos adicionales quedan `en_cola` con hora acordada y confirmada por el cliente; al cerrar el activo se desbloquea el siguiente. Máximo 2 en cola.
- Medición de tiempo de respuesta y de trabajos de origen frío.
### Fuera de alcance (deliberado, hasta después del lanzamiento)
- Pagos in-app / escrow. La propina es sugerida y registrada, no procesada.
- Llamadas de voz entre pro y cliente. Solo texto y audio de WhatsApp.
- App del pro. Chat en tiempo real propio. Calendario/agenda (la cola no es agenda).
- Programa de puntos, campañas pagadas.

### Capas futuras
- **Capa 2:** transacción — escrow, suscripción del cliente.
- **Capa 3:** productos financieros, contratos B2B con aseguradoras y administradoras de condominios, licencia del sello de verificación.

## 5b. Experiencia del pro (WhatsApp-first)

**Onboarding en el chat:** foto de cédula + selfie → KYC (Didit/Verifik contra JCE; si hace falta liveness fuerte, el bot manda un link de 1 minuto y vuelve al chat) → categorías y servicios que ofrece → PDF de la PGR (la pro lo saca ella misma; el sistema extrae el código y el equipo lo confirma en el portal) → 2 referencias (nombre, teléfono; el equipo las llama con guion de 3 preguntas) → portafolio (mínimo N fotos de trabajos, sin rostro de clientas o con consentimiento) → redes sociales (revisión interna) → certificado INFOTEP si lo tiene (se verifica por cédula) → zona → estado `pendiente` con checklist. Sin sello no llegan solicitudes.

**Solicitud:** llega como plantilla de WhatsApp con categoría, servicio, franja horaria pedida, zona, precio (provisional hasta cerrar §6b) y nombre del cliente. La pro responde solo **sí** o **no** (y variantes: ok, voy, dale / no puedo). Cualquier otra cosa se rebota. Al aceptar, se confirma hora exacta con el cliente por el relay.

**Despacho:** uno a uno, por ranking (rating, tiempo de respuesta) entre las pros con franja libre compatible. Si ninguna encaja, pros con cola disponible y oferta de hora. Si nadie acepta, escala al equipo. Respaldo manual del equipo el primer mes.

**Relay:** al aceptar, el pro recibe la dirección, nunca el teléfono. Mensajes, fotos, audios y ubicación se reenvían en ambos sentidos con prefijo de nombre. El bot bloquea números de teléfono y pedidos de llamada. Un pro con dos trabajos responde al activo; el de cola no puede escribirle hasta que se desbloquee (el bot contesta con hora y estado). `voy tarde, hora` reprograma al de la cola.

**Cierre:** fotos → `listo` → cliente califica (1–5, comentario, propina opcional por transferencia; el cliente pide la cuenta al bot) → cerrado. `perfil` muestra sello, rating, trabajos, tiempo de respuesta e historial.

**Copy:** Confía habla como empresa. Nunca se nombra a una persona del equipo ("nuestro equipo", "lo confirmamos"). Los únicos nombres en el chat son el del pro y el del cliente. Lenguaje de intermediación siempre: "te ponemos en contacto", "tú acuerdas con el cliente". El bot transmite, nunca instruye cómo hacer el trabajo.

**Infra:** WhatsApp Cloud API (Meta Business verificado, dos números, plantillas aprobadas) + n8n para los flujos + Supabase como fuente de verdad. n8n no guarda estado: todo va a la base de datos.

## 6. Modelo de negocio

- Ahora: membresía / lead fee del lado de la pro (modelo Booksy). El cliente no paga por usar la plataforma.
- Nunca comisión por transacción mientras el pago viva en WhatsApp — no hay forma de cobrarla.
- Referencia: la pro entrega hoy 40–50% al salón, así que cualquier fee razonable le sale barato.

## 6b. Precios — decisión abierta

Javi no tiene vía todavía. Son cuatro decisiones separadas, no una:
1. **Quién fija el precio del servicio** — la pro (Booksy) / Confía tabla fija (Urban Company) / bandas estándar-premium.
2. **Qué cobra Confía** — lead fee por trabajo cerrado o membresía mensual.
3. **Desplazamiento** — incluido, cargo fijo por zona, o lo acuerda la pro. Con una sola zona, incluido es lo más limpio.
4. **Cuándo empieza el fee** — principio vigente: RD$0 hasta tracción.

**Cómo se cierra:** a las primeras 5 pros reclutadas se les pregunta qué cobran hoy a domicilio por servicio, qué entregan al salón y si pagarían por trabajos que Confía les traiga. Con eso se fija modelo y tabla. Hasta entonces, precios de referencia marcados como **provisionales** en plantillas y prototipo.

Anclas de mercado a domicilio en SD (sep 2026): brushing RD$800–1,500 · manicura RD$500–900 · manicura+pedicura RD$1,000–1,800 · maquillaje de novia RD$2,500–6,000 · desplazamiento RD$200–600 según zona.

## 7. Posición legal (no negociable)

- Confía es **intermediario**. Nunca empleador, nunca proveedor directo, nunca supervisor.
- Lenguaje obligatorio y consistente en todo documento: "intermediación", "poner en contacto". Objeto social, CIIU, marca, T&C, copy del app. Una inconsistencia puede tumbar la defensa laboral.
- **No supervisamos el trabajo, verificamos el resultado.** Control de calidad post-trabajo (llamada, rating, disputa bajo garantía de 7 días). Nada de supervisores de campo.
- Leyes relevantes: Ley 172-13 (datos personales — los antecedentes de los pros son dato sensible; definir retención y borrado cuando un pro sale), Ley 20-00 (marcas), Código de Trabajo (clasificación de intermediario).
- **Relay de conversaciones:** consentimiento explícito de pro y cliente (Ley 172-13), política de retención de mensajes, y punto específico para el abogado: controlar el canal de comunicación es un indicio de subordinación laboral; se mitiga con que Confía transmite y no instruye.
- **Pendiente:** consulta con abogado dominicano antes de cobrar, sobre el relay, sobre depilación/estética y masaje (contacto dérmico, habilitación MSP), sobre el rating del cliente y los datos de pago (172-13), y sobre el uso de fotos de clientas en portafolios.
- Flags de marca: confia.do pertenece a una corredora de seguros activa (conflicto de dominio, sin resolver). AFP Popular tiene lemas en Clase 45 con raíz "confianza" — Clase 45 es de alto riesgo. **Clase 44 (servicios de belleza) no está cubierta por el registro actual:** buscar conflictos y registrar.

## 8. Stack y método de construcción

- **Lado del pro:** WhatsApp Cloud API + n8n. **Lado del cliente:** por ahora también WhatsApp; el app/PWA (Next.js) con la C modular por categoría viene después. **Backend/DB/Auth:** Supabase. Desarrollo en Claude Code.
- Base: el prototipo `index.html` (móvil primero, español, datos de Santo Domingo).
- Claves: usar `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` en cliente; la secret key solo en servidor.
- **Método:** área por área. Claude pregunta, Javi responde, las respuestas se convierten en el prompt de cada área. Este archivo es la fuente de verdad; se actualiza al cerrar cada área.
- Idioma del producto: español dominicano. Idioma del código y comentarios: inglés.

## 9. Principios

1. **Vender antes de construir** sigue vigente dentro de la construcción: cada área se justifica por un trabajo real que la necesita.
2. **Dilución es el modo de falla conocido.** No se agregan categorías, zonas ni features sin decisión escrita aquí.
3. **Trabajos fríos son la señal real.** Los de red personal no validan nada.
4. **Lenguaje de intermediación airtight** en todo lo que se escribe.
5. **Sin equity a colaboradores** hasta que haya tracción; crea presión política para continuar sin datos.
6. Cambios a este archivo se hacen con Victor al tanto. No hay secretos entre fundadores.

## 10. Decisiones abiertas

- [x] **Belleza a domicilio como única área de lanzamiento** (14–15 sep 2026). Marca Confía, C modular por categoría. Pendiente: registrar la razón del cambio y revisión con Victor.
- [ ] Precios: modelo, fee de Confía, desplazamiento, cuándo empieza el fee (ver §6b). Se cierra con las primeras 5 pros.
- [ ] Lista definitiva de categorías de belleza (placeholders en §4).
- [ ] Nuevo tagline (el actual habla de "hogar").
- [ ] Clase 44 en ONAPI.
- [ ] Depilación/estética y masaje: revisión legal antes de listar.
- [ ] Mínimo de fotos de portafolio y regla de rostro/consentimiento.
- [ ] Dominio (conflicto confia.do).
- [ ] Estructura societaria (SRL en evaluación).
- [x] Pro WhatsApp-first, sin app en v0. Relay con dos números. Cola secuencial (máx. 2). Sin llamadas. Cierre con fotos + rating + propina sugerida. Despacho uno a uno por disponibilidad.
- [x] Registro obligatorio del cliente (nombre, teléfono, dirección) + rating del cliente por las pros + registro de pago, uso interno.
- [ ] Servicios para el hogar (plomería, electricidad, etc.): fuera del lanzamiento. Vuelven solo por decisión escrita aquí.

## 11. Assets existentes

- `index.html` — prototipo interactivo, botones `wa.me` reales. Debe hospedarse para abrir en otros teléfonos.
- `confia-prototipo.pdf` — walkthrough estático de 9 páginas para feedback de concepto.
- `confia-hub.html` — hub de operaciones compartido (plan, KPIs, legal, presupuesto, tareas, agenda, notas).
- Google Sheet — PROS / SOLICITUDES / TRABAJOS.
- Guía de mystery shopping (10 métricas) para competidores.
- `confia-pro-whatsapp-demo.html` — demo interactiva del journey del pro dentro de WhatsApp (onboarding, solicitud, relay, cola, cierre).
- `confia-pro-data-map.md` + `confia-pro-erd.pdf` — modelo de datos 3NF.
- `confia-pro-journey.pdf` — flujo del pro de captación a mantenimiento.
