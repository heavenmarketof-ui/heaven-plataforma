import { supabase } from '@/integrations/supabase/client'

export async function listProductionBoard(companyId: string) {
  const { data, error } = await supabase.from('production_board').select('*').eq('company_id', companyId).order('separation_due_at')
  if (error) throw error
  return data ?? []
}

export async function prepareEventForProduction(eventId: string, dueAt?: string) {
  const { data, error } = await supabase.rpc('prepare_event_for_production', { target_event_id: eventId, due_at: dueAt ?? null })
  if (error) throw error
  return data as string
}

export async function markProductionReady(orderId: string) {
  const { error } = await supabase.rpc('mark_production_ready', { target_order_id: orderId })
  if (error) throw error
}

export async function syncEventLogistics(eventId: string) {
  const { data, error } = await supabase.rpc('sync_event_logistics', { target_event_id: eventId })
  if (error) throw error
  return Number(data ?? 0)
}

export async function closeEventOperation(eventId: string) {
  const { error } = await supabase.rpc('close_event_operation', { target_event_id: eventId })
  if (error) throw error
}
