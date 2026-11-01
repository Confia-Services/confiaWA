import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
)

export type Step = 'MENU' | 'PROFESSION' | 'NAME' | 'ZONE' | 'CEDULA' | 'CONFIRM' | 'EDIT_NAME' | 'EDIT_ZONE' | 'EDIT_CEDULA' | 'DONE'

export interface Conversation {
  id: string
  phone: string
  step: Step
  data: Record<string, string>
  created_at: string
}

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
    .insert({ phone, step: 'MENU', data: {} })
    .select()
    .single()
  if (error) throw error
  return row
}

export async function updateConversation(
  phone: string,
  step: Step,
  payload?: Record<string, string>
) {
  const update: Record<string, unknown> = { step }
  if (payload !== undefined) update.data = payload
  const { error } = await supabase
    .from('conversations')
    .update(update)
    .eq('phone', phone)
    .select()
    .single()
  if (error) console.error('updateConversation error:', error)
}

export async function insertPro(phone: string, data: Record<string, string>) {
  await supabase.from('pros').insert({
    phone,
    name: data.name,
    zone: data.zone,
    service: data.service,
    cedula: data.cedula,
    state: 'pending',
  })
}
