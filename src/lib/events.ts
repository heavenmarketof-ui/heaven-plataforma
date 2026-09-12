import { supabase } from '@/integrations/supabase/client'

export type EventStatus = 'planejamento' | 'confirmado' | 'em_preparacao' | 'em_execucao' | 'aguardando_devolucao' | 'concluido' | 'cancelado'
export type OperationType = 'retirada' | 'entrega' | 'montagem' | 'desmontagem' | 'devolucao' | 'conferencia' | 'outro'

export interface OperationalEvent {
  id: string
  company_id: string
  contract_id: string
  client_id: string
  title: string
  event_type: string | null
  starts_at: string
  ends_at: string | null
  venue_name: string | null
  address: string | null
  city: string | null
  state: string | null
  status: EventStatus
  responsible_user_id: string | null
}

export async function activateContract(contractId: string) {
  const { data, error } = await supabase.rpc('activate_contract_and_create_event', { target_contract_id: contractId })
  if (error) throw error
  return data as string
}

export async function listEvents(companyId: string, from: string, to: string) {
  const { data, error } = await supabase
    .from('events')
    .select('*')
    .eq('company_id', companyId)
    .gte('starts_at', from)
    .lte('starts_at', to)
    .order('starts_at')
  if (error) throw error
  return (data ?? []) as OperationalEvent[]
}

export async function createOperation(companyId: string, eventId: string, input: {
  operationType: OperationType
  scheduledAt?: string | null
  scheduledEndAt?: string | null
  address?: string | null
  responsibleUserId?: string | null
  notes?: string | null
}) {
  const { data, error } = await supabase.from('event_operations').insert({
    company_id: companyId,
    event_id: eventId,
    operation_type: input.operationType,
    scheduled_at: input.scheduledAt ?? null,
    scheduled_end_at: input.scheduledEndAt ?? null,
    address: input.address ?? null,
    responsible_user_id: input.responsibleUserId ?? null,
    notes: input.notes ?? null,
  }).select('*').single()
  if (error) throw error
  return data
}
