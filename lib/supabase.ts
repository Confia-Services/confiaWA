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
  const { data } = await supabase
    .from('conversations')
    .select('*')
    .eq('phone', phone)
    .single()
  return data ?? null
}

export async function createConversation(phone: string): Promise<Conversation> {
  const { data, error } = await supabase
    .from('conversations')
    .insert({ phone, step: 'MENU', data: {} })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function updateConversation(
  phone: string,
  step: Step,
  data?: Record<string, string>
) {
  const update: Record<string, unknown> = { step }
  if (data !== undefined) update.data = data
  await supabase.from('conversations').update(update).eq('phone', phone)
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
