import { NextRequest } from 'next/server'
import { sendMessage } from '@/lib/whatsapp'
import {
  getConversation,
  createConversation,
  updateConversation,
  insertPro,
  type Conversation,
  type Step,
} from '@/lib/supabase'

type DisplayData = {
  name: string | null
  service: string | null
  specialty: string | null
  rate: string | null
  zone: string | null
  cedula: string | null
}

const SPECIALTY_EXAMPLES: Record<string, string> = {
  'Masaje': 'relajante, deportivo, piedras calientes',
  'Depilación y estética': 'cera, depilación facial, tratamientos',
  'Maquillaje': 'novias, artístico, natural',
  'Barbería': 'fade, lineups, afeitado clásico',
  'Peluquería': 'coloración, keratina, corte',
  'Uñas': 'gel, acrílico, nail art',
}

const MSG = {
  welcome: `Bienvenido a Confía, servicios a domicilio en Santo Domingo.

¿Qué desea hacer?
1️⃣ Registrarme como profesional
2️⃣ Solicitar un servicio`,

  menuFallback: `Por favor responda con 1 para registrarse como profesional o 2 para solicitar un servicio.`,

  ordersComingSoon: `La solicitud de servicios estará disponible próximamente.

Si desea registrarse como profesional, escriba 1.`,

  professionMenu: `¿Cuál es su servicio principal?

1️⃣ Masaje
2️⃣ Depilación y estética
3️⃣ Maquillaje
4️⃣ Barbería
5️⃣ Peluquería
6️⃣ Uñas`,

  professionFallback: `Responda con el número correspondiente a su servicio:

1️⃣ Masaje
2️⃣ Depilación y estética
3️⃣ Maquillaje
4️⃣ Barbería
5️⃣ Peluquería
6️⃣ Uñas`,

  askSpecialty: (service: string | null) => {
    const examples = SPECIALTY_EXAMPLES[service ?? ''] ?? 'masajes, coloración, uñas gel'
    return `¿Tiene alguna especialidad? Escríbala brevemente (ej. ${examples}) o escriba ninguna.`
  },

  specialtyFallback: `Por favor escriba su especialidad o escriba ninguna.`,

  askPrice: `¿Cuánto cobra por servicio en pesos dominicanos? Solo el número (ejemplo: 1500).`,

  priceFallback: `Por favor escriba un monto válido en pesos dominicanos (solo números, ejemplo: 1500).`,

  askName: `¿Cuál es su nombre completo, tal como aparece en su cédula?`,

  nameFallback: `Por favor escriba su nombre completo.`,

  askZone: `¿En qué zona de Santo Domingo ofrece sus servicios?

1️⃣ Naco
2️⃣ Piantini
3️⃣ Gazcue
4️⃣ Bella Vista`,

  zoneFallback: `Responda con el número de su zona:

1️⃣ Naco
2️⃣ Piantini
3️⃣ Gazcue
4️⃣ Bella Vista`,

  askCedula: `Escriba su número de cédula dominicana (11 dígitos, ejemplo: 00100000000 o 001-0000000-0).`,

  cedulaFallback: `La cédula debe tener 11 dígitos. Escríbala sin guiones o con guiones (ejemplo: 00100000000 o 001-0000000-0).`,

  confirm: (d: DisplayData) =>
    `Verifique sus datos:

Nombre: ${d.name ?? '—'}
Servicio: ${d.service ?? '—'}
Especialidad: ${d.specialty ?? 'Ninguna'}
Precio por servicio: RD$${d.rate ?? '—'}
Zona: ${d.zone ?? '—'}
Cédula: ${d.cedula ? formatCedula(d.cedula) : '—'}

1️⃣ Confirmar
2️⃣ Corregir nombre
3️⃣ Corregir servicio
4️⃣ Corregir especialidad
5️⃣ Corregir precio
6️⃣ Corregir zona
7️⃣ Corregir cédula
8️⃣ Empezar de nuevo`,

  confirmFallback: `Responda con el número de su opción: 1 confirmar, 2–7 corregir un campo, 8 empezar de nuevo.`,

  askEditName: `Escriba su nombre correcto.`,

  askEditService: `¿Cuál es su servicio correcto?

1️⃣ Masaje
2️⃣ Depilación y estética
3️⃣ Maquillaje
4️⃣ Barbería
5️⃣ Peluquería
6️⃣ Uñas`,

  askEditSpecialty: (service: string | null) => {
    const examples = SPECIALTY_EXAMPLES[service ?? ''] ?? 'masajes, coloración, uñas gel'
    return `Escriba su especialidad correcta (ej. ${examples}) o escriba ninguna.`
  },

  askEditPrice: `Escriba su precio correcto en pesos dominicanos (solo el número).`,

  askEditZone: `¿Cuál es su zona correcta?

1️⃣ Naco
2️⃣ Piantini
3️⃣ Gazcue
4️⃣ Bella Vista`,

  askEditCedula: `Escriba su cédula correcta (11 dígitos, ejemplo: 00100000000 o 001-0000000-0).`,

  done: (d: DisplayData) =>
    `Registro confirmado.

Nombre: ${d.name}
Servicio: ${d.service}
Especialidad: ${d.specialty ?? 'Ninguna'}
Precio por servicio: RD$${d.rate}
Zona: ${d.zone}
Cédula: ${d.cedula ? formatCedula(d.cedula) : '—'}

Le contactaremos en los próximos días.`,

  alreadyRegistered: `Su registro ya fue recibido. Le contactaremos pronto.

Si tiene alguna duda, comuníquese con nuestro equipo.`,

  nonText: `Solo procesamos mensajes de texto. Por favor escriba su respuesta.`,

  error: `Hubo un problema procesando su mensaje. Por favor intente de nuevo.`,
}

const PROFESSIONS: Record<string, string> = {
  '1': 'Masaje',
  '2': 'Depilación y estética',
  '3': 'Maquillaje',
  '4': 'Barbería',
  '5': 'Peluquería',
  '6': 'Uñas',
}

const ZONES: Record<string, string> = {
  '1': 'Naco',
  '2': 'Piantini',
  '3': 'Gazcue',
  '4': 'Bella Vista',
}

async function handleMenu(phone: string, text: string) {
  if (text === '1') {
    await updateConversation(phone, 'PROFESSION')
    await sendMessage(phone, MSG.professionMenu)
  } else if (text === '2') {
    await sendMessage(phone, MSG.ordersComingSoon)
  } else {
    await sendMessage(phone, MSG.menuFallback)
  }
}

async function handleProfession(phone: string, text: string) {
  const service = PROFESSIONS[text]
  if (!service) {
    await sendMessage(phone, MSG.professionFallback)
    return
  }
  await updateConversation(phone, 'SPECIALTY', { service })
  await sendMessage(phone, MSG.askSpecialty(service))
}

async function handleSpecialty(phone: string, text: string, conv: Conversation) {
  if (text.length < 2) {
    await sendMessage(phone, MSG.specialtyFallback)
    return
  }
  const specialty = text.toLowerCase() === 'ninguna' ? 'ninguna' : text
  await updateConversation(phone, 'PRICE', { specialty })
  await sendMessage(phone, MSG.askPrice)
}

async function handlePrice(phone: string, text: string) {
  const cleaned = text.replace(/[^\d.]/g, '')
  const num = parseFloat(cleaned)
  if (isNaN(num) || num <= 0) {
    await sendMessage(phone, MSG.priceFallback)
    return
  }
  await updateConversation(phone, 'NAME', { rate: cleaned })
  await sendMessage(phone, MSG.askName)
}

async function handleName(phone: string, text: string) {
  if (text.length < 3) {
    await sendMessage(phone, MSG.nameFallback)
    return
  }
  await updateConversation(phone, 'ZONE', { name: text })
  await sendMessage(phone, MSG.askZone)
}

async function handleZone(phone: string, text: string) {
  const zone = ZONES[text]
  if (!zone) {
    await sendMessage(phone, MSG.zoneFallback)
    return
  }
  await updateConversation(phone, 'CEDULA', { zone })
  await sendMessage(phone, MSG.askCedula)
}

function parseCedula(text: string): string | null {
  const digits = text.replace(/\D/g, '')
  if (digits.length !== 11) return null
  return digits
}

function formatCedula(cedula: string): string {
  return `${cedula.slice(0, 3)}-${cedula.slice(3, 10)}-${cedula.slice(10)}`
}

async function handleCedula(phone: string, text: string, conv: Conversation) {
  const cedula = parseCedula(text)
  if (!cedula) {
    await sendMessage(phone, MSG.cedulaFallback)
    return
  }
  await updateConversation(phone, 'CONFIRM', { cedula })
  await sendMessage(phone, MSG.confirm({ ...conv, cedula }))
}

async function handleConfirm(phone: string, text: string, conv: Conversation) {
  if (text === '1') {
    await insertPro(conv)
    await updateConversation(phone, 'DONE')
    await sendMessage(phone, MSG.done(conv))
  } else if (text === '2') {
    await updateConversation(phone, 'EDIT_NAME')
    await sendMessage(phone, MSG.askEditName)
  } else if (text === '3') {
    await updateConversation(phone, 'EDIT_SERVICE')
    await sendMessage(phone, MSG.askEditService)
  } else if (text === '4') {
    await updateConversation(phone, 'EDIT_SPECIALTY')
    await sendMessage(phone, MSG.askEditSpecialty(conv.service))
  } else if (text === '5') {
    await updateConversation(phone, 'EDIT_PRICE')
    await sendMessage(phone, MSG.askEditPrice)
  } else if (text === '6') {
    await updateConversation(phone, 'EDIT_ZONE')
    await sendMessage(phone, MSG.askEditZone)
  } else if (text === '7') {
    await updateConversation(phone, 'EDIT_CEDULA')
    await sendMessage(phone, MSG.askEditCedula)
  } else if (text === '8') {
    await updateConversation(phone, 'MENU', {
      service: null, specialty: null, rate: null,
      name: null, zone: null, cedula: null,
    })
    await sendMessage(phone, MSG.welcome)
  } else {
    await sendMessage(phone, MSG.confirmFallback)
  }
}

async function handleEditName(phone: string, text: string, conv: Conversation) {
  if (text.length < 3) {
    await sendMessage(phone, MSG.nameFallback)
    return
  }
  await updateConversation(phone, 'CONFIRM', { name: text })
  await sendMessage(phone, MSG.confirm({ ...conv, name: text }))
}

async function handleEditService(phone: string, text: string, conv: Conversation) {
  const service = PROFESSIONS[text]
  if (!service) {
    await sendMessage(phone, MSG.professionFallback)
    return
  }
  await updateConversation(phone, 'CONFIRM', { service })
  await sendMessage(phone, MSG.confirm({ ...conv, service }))
}

async function handleEditSpecialty(phone: string, text: string, conv: Conversation) {
  if (text.length < 2) {
    await sendMessage(phone, MSG.specialtyFallback)
    return
  }
  const specialty = text.toLowerCase() === 'ninguna' ? 'ninguna' : text
  await updateConversation(phone, 'CONFIRM', { specialty })
  await sendMessage(phone, MSG.confirm({ ...conv, specialty }))
}

async function handleEditPrice(phone: string, text: string, conv: Conversation) {
  const cleaned = text.replace(/[^\d.]/g, '')
  const num = parseFloat(cleaned)
  if (isNaN(num) || num <= 0) {
    await sendMessage(phone, MSG.priceFallback)
    return
  }
  await updateConversation(phone, 'CONFIRM', { rate: cleaned })
  await sendMessage(phone, MSG.confirm({ ...conv, rate: cleaned }))
}

async function handleEditZone(phone: string, text: string, conv: Conversation) {
  const zone = ZONES[text]
  if (!zone) {
    await sendMessage(phone, MSG.zoneFallback)
    return
  }
  await updateConversation(phone, 'CONFIRM', { zone })
  await sendMessage(phone, MSG.confirm({ ...conv, zone }))
}

async function handleEditCedula(phone: string, text: string, conv: Conversation) {
  const cedula = parseCedula(text)
  if (!cedula) {
    await sendMessage(phone, MSG.cedulaFallback)
    return
  }
  await updateConversation(phone, 'CONFIRM', { cedula })
  await sendMessage(phone, MSG.confirm({ ...conv, cedula }))
}

async function handleDone(phone: string) {
  await sendMessage(phone, MSG.alreadyRegistered)
}

async function routeStep(step: Step, phone: string, text: string, conv: Conversation) {
  switch (step) {
    case 'MENU':
      return handleMenu(phone, text)
    case 'PROFESSION':
      return handleProfession(phone, text)
    case 'SPECIALTY':
      return handleSpecialty(phone, text, conv)
    case 'PRICE':
      return handlePrice(phone, text)
    case 'NAME':
      return handleName(phone, text)
    case 'ZONE':
      return handleZone(phone, text)
    case 'CEDULA':
      return handleCedula(phone, text, conv)
    case 'CONFIRM':
      return handleConfirm(phone, text, conv)
    case 'EDIT_NAME':
      return handleEditName(phone, text, conv)
    case 'EDIT_SERVICE':
      return handleEditService(phone, text, conv)
    case 'EDIT_SPECIALTY':
      return handleEditSpecialty(phone, text, conv)
    case 'EDIT_PRICE':
      return handleEditPrice(phone, text, conv)
    case 'EDIT_ZONE':
      return handleEditZone(phone, text, conv)
    case 'EDIT_CEDULA':
      return handleEditCedula(phone, text, conv)
    case 'DONE':
      return handleDone(phone)
  }
}

export async function GET(req: NextRequest) {
  const { searchParams } = req.nextUrl
  const mode = searchParams.get('hub.mode')
  const token = searchParams.get('hub.verify_token')
  const challenge = searchParams.get('hub.challenge')

  if (mode === 'subscribe' && token === process.env.WEBHOOK_VERIFY_TOKEN) {
    console.log('webhook verified')
    return new Response(challenge, { status: 200 })
  }
  return new Response('Forbidden', { status: 403 })
}

export async function POST(req: NextRequest) {
  let body: unknown
  try {
    body = await req.json()
  } catch {
    return new Response('Bad Request', { status: 400 })
  }

  const entry = (body as any)?.entry?.[0]
  const value = entry?.changes?.[0]?.value
  if (!value?.messages) return new Response('OK', { status: 200 })

  const message = value.messages[0]
  const phone: string = message.from

  try {
    if (message.type !== 'text') {
      await sendMessage(phone, MSG.nonText)
      return new Response('OK', { status: 200 })
    }

    const text = (message.text.body as string).trim()
    if (!text) return new Response('OK', { status: 200 })

    let conv = await getConversation(phone)

    if (!conv) {
      conv = await createConversation(phone)
      await sendMessage(phone, MSG.welcome)
    } else {
      await routeStep(conv.step, phone, text, conv)
    }
  } catch (err) {
    console.error('webhook error:', err)
    try { await sendMessage(phone, MSG.error) } catch { /* silent */ }
  }

  return new Response('OK', { status: 200 })
}
