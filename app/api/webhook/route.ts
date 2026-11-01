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
  zone: string | null
  cedula: string | null
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

  askName: `¿Cuál es su nombre completo, tal como aparece en su cédula?`,

  nameFallback: `Por favor escriba su nombre completo.`,

  askZone: `¿En qué zona de Santo Domingo ofrece sus servicios?

1️⃣ Naco
2️⃣ Piantini
3️⃣ Evaristo Morales
4️⃣ Los Cacicazgos
5️⃣ Bella Vista
6️⃣ La Esperilla
7️⃣ Serrallés
8️⃣ Otra zona`,

  zoneFallback: `Responda con el número de su zona:

1️⃣ Naco
2️⃣ Piantini
3️⃣ Evaristo Morales
4️⃣ Los Cacicazgos
5️⃣ Bella Vista
6️⃣ La Esperilla
7️⃣ Serrallés
8️⃣ Otra zona`,

  askCedula: `Escriba su número de cédula (ejemplo: 001-0000000-0).`,

  cedulaFallback: `Por favor escriba su número de cédula.`,

  confirm: (d: DisplayData) =>
    `Verifique sus datos:

Nombre: ${d.name ?? '—'}
Servicio: ${d.service ?? '—'}
Zona: ${d.zone ?? '—'}
Cédula: ${d.cedula ?? '—'}

1️⃣ Confirmar
2️⃣ Corregir nombre
3️⃣ Corregir servicio
4️⃣ Corregir zona
5️⃣ Corregir cédula
6️⃣ Empezar de nuevo`,

  confirmFallback: `Responda con el número de su opción: 1 confirmar, 2 corregir nombre, 3 corregir servicio, 4 corregir zona, 5 corregir cédula, 6 empezar de nuevo.`,

  askEditName: `Escriba su nombre correcto.`,

  askEditService: `¿Cuál es su servicio correcto?

1️⃣ Masaje
2️⃣ Depilación y estética
3️⃣ Maquillaje
4️⃣ Barbería
5️⃣ Peluquería
6️⃣ Uñas`,

  askEditZone: `¿Cuál es su zona correcta?

1️⃣ Naco
2️⃣ Piantini
3️⃣ Evaristo Morales
4️⃣ Los Cacicazgos
5️⃣ Bella Vista
6️⃣ La Esperilla
7️⃣ Serrallés
8️⃣ Otra zona`,

  askEditCedula: `Escriba su cédula correcta (ejemplo: 001-0000000-0).`,

  done: (d: DisplayData) =>
    `Registro confirmado.

Nombre: ${d.name}
Servicio: ${d.service}
Zona: ${d.zone}
Cédula: ${d.cedula}

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
  '3': 'Evaristo Morales',
  '4': 'Los Cacicazgos',
  '5': 'Bella Vista',
  '6': 'La Esperilla',
  '7': 'Serrallés',
  '8': 'Otra zona',
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
  await updateConversation(phone, 'NAME', { service })
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

async function handleCedula(phone: string, text: string, conv: Conversation) {
  const cedula = text.replace(/\s/g, '')
  if (cedula.length < 5) {
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
    await updateConversation(phone, 'EDIT_ZONE')
    await sendMessage(phone, MSG.askEditZone)
  } else if (text === '5') {
    await updateConversation(phone, 'EDIT_CEDULA')
    await sendMessage(phone, MSG.askEditCedula)
  } else if (text === '6') {
    await updateConversation(phone, 'MENU', { service: null, name: null, zone: null, cedula: null })
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
  const cedula = text.replace(/\s/g, '')
  if (cedula.length < 5) {
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
