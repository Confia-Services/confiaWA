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

  confirm: (data: Record<string, string>) =>
    `Verifique sus datos:

Nombre: ${data.name}
Servicio: ${data.service}
Zona: ${data.zone}
Cédula: ${data.cedula}

1️⃣ Confirmar
2️⃣ Corregir nombre
3️⃣ Corregir zona
4️⃣ Corregir cédula
5️⃣ Empezar de nuevo`,

  confirmFallback: `Responda con una de las opciones: 1 para confirmar, 2 para corregir nombre, 3 para corregir zona, 4 para corregir cédula, o 5 para empezar de nuevo.`,

  askEditName: `Escriba su nombre correcto.`,
  askEditZone: `Escriba el sector correcto.`,
  askEditCedula: `Escriba su cédula correcta.`,

  done: (data: Record<string, string>) =>
    `Registro confirmado.

Nombre: ${data.name}
Servicio: ${data.service}
Zona: ${data.zone}
Cédula: ${data.cedula}

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

async function handleMenu(phone: string, text: string, conv: Conversation) {
  if (text === '1') {
    await updateConversation(phone, 'PROFESSION')
    await sendMessage(phone, MSG.professionMenu)
  } else if (text === '2') {
    await sendMessage(phone, MSG.ordersComingSoon)
  } else {
    await sendMessage(phone, MSG.menuFallback)
  }
}

async function handleProfession(phone: string, text: string, conv: Conversation) {
  const service = PROFESSIONS[text]
  if (!service) {
    await sendMessage(phone, MSG.professionFallback)
    return
  }
  const data = { ...conv.data, service }
  await updateConversation(phone, 'NAME', data)
  await sendMessage(phone, MSG.askName)
}

async function handleName(phone: string, text: string, conv: Conversation) {
  if (text.length < 3) {
    await sendMessage(phone, MSG.nameFallback)
    return
  }
  const data = { ...conv.data, name: text }
  await updateConversation(phone, 'ZONE', data)
  await sendMessage(phone, MSG.askZone)
}

async function handleZone(phone: string, text: string, conv: Conversation) {
  const zone = ZONES[text]
  if (!zone) {
    await sendMessage(phone, MSG.zoneFallback)
    return
  }
  const data = { ...conv.data, zone }
  await updateConversation(phone, 'CEDULA', data)
  await sendMessage(phone, MSG.askCedula)
}

async function handleCedula(phone: string, text: string, conv: Conversation) {
  const cedula = text.replace(/\s/g, '')
  if (cedula.length < 5) {
    await sendMessage(phone, MSG.cedulaFallback)
    return
  }
  const data = { ...conv.data, cedula }
  await updateConversation(phone, 'CONFIRM', data)
  await sendMessage(phone, MSG.confirm(data))
}

async function handleConfirm(phone: string, text: string, conv: Conversation) {
  if (text === '1') {
    await insertPro(phone, conv.data)
    await updateConversation(phone, 'DONE')
    await sendMessage(phone, MSG.done(conv.data))
  } else if (text === '2') {
    await updateConversation(phone, 'EDIT_NAME')
    await sendMessage(phone, MSG.askEditName)
  } else if (text === '3') {
    await updateConversation(phone, 'EDIT_ZONE')
    await sendMessage(phone, MSG.askEditZone)
  } else if (text === '4') {
    await updateConversation(phone, 'EDIT_CEDULA')
    await sendMessage(phone, MSG.askEditCedula)
  } else if (text === '5') {
    await updateConversation(phone, 'MENU', {})
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
  const data = { ...conv.data, name: text }
  await updateConversation(phone, 'CONFIRM', data)
  await sendMessage(phone, MSG.confirm(data))
}

async function handleEditZone(phone: string, text: string, conv: Conversation) {
  const zone = ZONES[text]
  if (!zone) {
    await sendMessage(phone, MSG.zoneFallback)
    return
  }
  const data = { ...conv.data, zone }
  await updateConversation(phone, 'CONFIRM', data)
  await sendMessage(phone, MSG.confirm(data))
}

async function handleEditCedula(phone: string, text: string, conv: Conversation) {
  const cedula = text.replace(/\s/g, '')
  if (cedula.length < 5) {
    await sendMessage(phone, MSG.cedulaFallback)
    return
  }
  const data = { ...conv.data, cedula }
  await updateConversation(phone, 'CONFIRM', data)
  await sendMessage(phone, MSG.confirm(data))
}

async function handleDone(phone: string) {
  await sendMessage(phone, MSG.alreadyRegistered)
}

async function routeStep(step: Step, phone: string, text: string, conv: Conversation) {
  switch (step) {
    case 'MENU':
      return handleMenu(phone, text, conv)
    case 'PROFESSION':
      return handleProfession(phone, text, conv)
    case 'NAME':
      return handleName(phone, text, conv)
    case 'ZONE':
      return handleZone(phone, text, conv)
    case 'CEDULA':
      return handleCedula(phone, text, conv)
    case 'CONFIRM':
      return handleConfirm(phone, text, conv)
    case 'EDIT_NAME':
      return handleEditName(phone, text, conv)
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
