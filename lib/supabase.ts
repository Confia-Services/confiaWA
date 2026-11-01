import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

export type Step =
  | 'MENU'
  | 'PROFESSION'
  | 'NAME'
  | 'ZONE'
  | 'CEDULA'
  | 'CONFIRM'
  | 'EDIT_NAME'
  | 'EDIT_SERVICE'
  | 'EDIT_ZONE'
  | 'EDIT_CEDULA'
  | 'DONE'

export interface Conversation {
  id: string
  phone: string
  step: Step
  service: string | null
  name: string | null
  zone: string | null
  cedula: string | null
  created_at: string
}

type ConvFields = Partial<{
  service: string | null
  name: string | null
  zone: string | null
  cedula: string | null
}>

export async function getConversation(phone: string): Promise<Conversation | null> {
  const { data: row, error } = await supabase
    .from('conversations')
    .select('*')
    .eq('phone', phone)
    .single()
  if (error && error.code !== 'PGRST116') {
    console.error('getConversation error:', error)
  }
  return row ?? null
}

export async function createConversation(phone: string): Promise<Conversation> {
  const { data: row, error } = await supabase
    .from('conversations')
    .insert({ phone, step: 'MENU' })
    .select()
    .single()
  if (error) throw error
  return row
}

export async function updateConversation(
  phone: string,
  step: Step,
  fields?: ConvFields
) {
  const { error } = await supabase
    .from('conversations')
    .update({ step, ...fields })
    .eq('phone', phone)
  if (error) console.error('updateConversation error:', error)
}

export async function insertPro(conv: Conversation) {
  const { error } = await supabase.from('pros').insert({
    phone: conv.phone,
    name: conv.name,
    zone: conv.zone,
    service: conv.service,
    cedula: conv.cedula,
    state: 'pending',
  })
  if (error) console.error('insertPro error:', error)
}
