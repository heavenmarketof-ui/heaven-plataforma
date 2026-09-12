import { supabase } from '@/integrations/supabase/client'

export type LogisticsStatus = 'planejado' | 'confirmado' | 'em_rota' | 'no_local' | 'concluido' | 'cancelado'

export async function listLogistics(companyId: string, from?: string, until?: string) {
  let query = supabase.from('logistics_runs').select('*, events(title, starts_at, city)').eq('company_id', companyId)
  if (from) query = query.gte('scheduled_at', from)
  if (until) query = query.lte('scheduled_at', until)
  const { data, error } = await query.order('scheduled_at')
  if (error) throw error
  return data ?? []
}

export async function updateLogisticsStatus(runId: string, status: LogisticsStatus) {
  const now = new Date().toISOString()
  const patch: Record<string, unknown> = { status, updated_at: now }
  if (status === 'em_rota') patch.started_at = now
  if (status === 'no_local') patch.arrived_at = now
  if (status === 'concluido') patch.completed_at = now
  const { error } = await supabase.from('logistics_runs').update(patch).eq('id', runId)
  if (error) throw error
}
