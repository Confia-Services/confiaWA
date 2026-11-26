import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

const CHANNEL = 'whatsapp'
const LINE = 'pros'

export type Step =
  | 'MENU' | 'PROFESSION' | 'SPECIALTY' | 'PRICE' | 'NAME' | 'ZONE' | 'CEDULA' | 'CONFIRM'
  | 'EDIT_NAME' | 'EDIT_SERVICE' | 'EDIT_SPECIALTY' | 'EDIT_PRICE' | 'EDIT_ZONE' | 'EDIT_CEDULA' | 'DONE'

export interface Conversation {
  phone: string
  step: Step
  service: string | null
  specialty: string | null
  rate: string | null
  name: string | null
  zone: string | null
  cedula: string | null
}

type ConvFields = Partial<{
  service: string | null
  specialty: string | null
  rate: string | null
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
    specialty: ctx.specialty ?? null,
    rate: ctx.rate ?? null,
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
    .eq('line', LINE)
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
      line: LINE,
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
      .eq('line', LINE)
      .eq('external_id', phone)
      .single()

    const newContext = { ...((current?.context as object) ?? {}), ...fields }

    const { error } = await supabase
      .from('bot_sessions')
      .update({ state: step, context: newContext })
      .eq('channel', CHANNEL)
      .eq('line', LINE)
      .eq('external_id', phone)
    if (error) console.error('updateConversation error:', error)
  } else {
    const { error } = await supabase
      .from('bot_sessions')
      .update({ state: step })
      .eq('channel', CHANNEL)
      .eq('line', LINE)
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
  const { data: zoneRow, error: zoneError } = await supabase
    .from('zones')
    .select('id')
    .eq('name', conv.zone)
    .single()

  if (zoneError || !zoneRow) {
    console.error('insertPro: zone lookup failed for:', conv.zone, zoneError)
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
    console.error('insertPro: pros insert failed:', proError)
    return
  }

  const categorySlug = CATEGORY_SLUGS[conv.service ?? '']
  if (!categorySlug) {
    console.error('insertPro: unknown service slug for:', conv.service)
    return
  }

  const { data: catRow, error: catLookupError } = await supabase
    .from('categories')
    .select('id')
    .eq('slug', categorySlug)
    .single()

  if (catLookupError || !catRow) {
    console.error('insertPro: category lookup failed for slug:', categorySlug, catLookupError)
    return
  }

  const rateNum = conv.rate ? parseFloat(conv.rate) : null

  const { error: catError } = await supabase
    .from('pro_categories')
    .insert({
      pro_id: (pro as { id: string }).id,
      category_id: (catRow as { id: string }).id,
      status: 'pendiente',
      rate: rateNum,
      specialty: conv.specialty === 'ninguna' ? null : conv.specialty,
    })

  if (catError) {
    console.error('insertPro: pro_categories insert failed:', catError)
  }
}
