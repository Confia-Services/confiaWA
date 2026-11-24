import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

const CHANNEL = 'whatsapp'
const line = () => process.env.WHATSAPP_PHONE_ID!

export type Step =
  | 'MENU' | 'PROFESSION' | 'NAME' | 'ZONE' | 'CEDULA' | 'CONFIRM'
  | 'EDIT_NAME' | 'EDIT_SERVICE' | 'EDIT_ZONE' | 'EDIT_CEDULA' | 'DONE'

export interface Conversation {
  phone: string
  step: Step
  service: string | null
  name: string | null
  zone: string | null
  cedula: string | null
}

type ConvFields = Partial<{
  service: string | null
  name: string | null
  zone: string | null
  cedula: string | null
}>

function rowToConv(row: Record<string, unknown>): Conversation {
  const ctx = (row.context ?? {}) as Record<string, string | null>
  return {
    phone: row.external_id as string,
    step: row.state as Step,
    service: ctx.service ?? null,
    name: ctx.name ?? null,
    zone: ctx.zone ?? null,
    cedula: ctx.cedula ?? null,
  }
}

export async function getConversation(phone: string): Promise<Conversation | null> {
  const { data: row, error } = await supabase
    .from('bot_sessions')
    .select('*')
    .eq('channel', CHANNEL)
    .eq('line', line())
    .eq('external_id', phone)
    .single()
  if (error && error.code !== 'PGRST116') {
    console.error('getConversation error:', error)
  }
  return row ? rowToConv(row as Record<string, unknown>) : null
}

export async function createConversation(phone: string): Promise<Conversation> {
  const { data: row, error } = await supabase
    .from('bot_sessions')
    .insert({
      channel: CHANNEL,
      line: line(),
      external_id: phone,
      party_type: 'pro',
      state: 'MENU',
      context: {},
    })
    .select()
    .single()
  if (error) throw error
  return rowToConv(row as Record<string, unknown>)
}

export async function updateConversation(
  phone: string,
  step: Step,
  fields?: ConvFields
) {
  if (fields !== undefined) {
    const { data: current } = await supabase
      .from('bot_sessions')
      .select('context')
      .eq('channel', CHANNEL)
      .eq('line', line())
      .eq('external_id', phone)
      .single()

    const newContext = { ...((current?.context as object) ?? {}), ...fields }

    const { error } = await supabase
      .from('bot_sessions')
      .update({ state: step, context: newContext })
      .eq('channel', CHANNEL)
      .eq('line', line())
      .eq('external_id', phone)
    if (error) console.error('updateConversation error:', error)
  } else {
    const { error } = await supabase
      .from('bot_sessions')
      .update({ state: step })
      .eq('channel', CHANNEL)
      .eq('line', line())
      .eq('external_id', phone)
    if (error) console.error('updateConversation error:', error)
  }
}

const CATEGORY_SLUGS: Record<string, string> = {
  'Masaje': 'masaje',
  'Depilación y estética': 'depilacion',
  'Maquillaje': 'maquillaje',
  'Barbería': 'barberia',
  'Peluquería': 'peluqueria',
  'Uñas': 'unas',
}

export async function insertPro(conv: Conversation) {
  const { data: zoneRow } = await supabase
    .from('zones')
    .select('id')
    .eq('name', conv.zone)
    .single()

  if (!zoneRow) {
    console.error('insertPro: zone not found:', conv.zone)
    return
  }

  const phone = conv.phone.startsWith('+') ? conv.phone : `+${conv.phone}`

  const { data: pro, error: proError } = await supabase
    .from('pros')
    .insert({
      phone,
      display_name: conv.name,
      zone_id: (zoneRow as { id: string }).id,
      cedula: conv.cedula,
    })
    .select('id')
    .single()

  if (proError) {
    console.error('insertPro error:', proError)
    return
  }

  const categorySlug = CATEGORY_SLUGS[conv.service ?? '']
  if (!categorySlug) {
    console.error('insertPro: unknown service:', conv.service)
    return
  }

  const { data: catRow } = await supabase
    .from('categories')
    .select('id')
    .eq('slug', categorySlug)
    .single()

  if (!catRow) {
    console.error('insertPro: category not found:', categorySlug)
    return
  }

  const { error: catError } = await supabase
    .from('pro_categories')
    .insert({
      pro_id: (pro as { id: string }).id,
      category_id: (catRow as { id: string }).id,
      status: 'pendiente',
    })

  if (catError) console.error('insertProCategory error:', catError)
}
