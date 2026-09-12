import { supabase } from '@/integrations/supabase/client'

export interface TodayAction {
  company_id: string
  source_type: 'task' | 'operation'
  source_id: string
  title: string
  description: string | null
  scheduled_at: string | null
  priority: number
  action_type: string | null
  action_payload: Record<string, unknown>
  assigned_user_id: string | null
}

export async function listTodayActions(companyId: string, dayStart: string, dayEnd: string) {
  const { data, error } = await supabase
    .from('today_actions')
    .select('*')
    .eq('company_id', companyId)
    .or(`scheduled_at.is.null,and(scheduled_at.gte.${dayStart},scheduled_at.lte.${dayEnd})`)
    .order('priority', { ascending: false })
    .order('scheduled_at', { ascending: true, nullsFirst: true })
  if (error) throw error
  return (data ?? []) as TodayAction[]
}

export async function completeTask(taskId: string) {
  const now = new Date().toISOString()
  const { error } = await supabase.from('tasks').update({ status: 'concluida', completed_at: now, updated_at: now }).eq('id', taskId)
  if (error) throw error
}

export async function completeOperation(operationId: string) {
  const { error } = await supabase.from('event_operations').update({ status: 'concluida', updated_at: new Date().toISOString() }).eq('id', operationId)
  if (error) throw error
}
