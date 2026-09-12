import { supabase } from '@/integrations/supabase/client'

export interface ManagementSummary {
  sales_total: number
  sales_count: number
  average_ticket: number
  event_total: number
  event_count: number
  received: number
  paid: number
  operating_cash: number
  overdue_receivable: number
  leads_count: number
  won_count: number
  conversion_rate: number
}

export async function getManagementSummary(companyId: string, from: string, until: string) {
  const { data, error } = await supabase.rpc('management_summary', {
    target_company_id: companyId,
    period_from: from,
    period_until: until,
  })
  if (error) throw error
  return data as ManagementSummary
}

export async function listManagementAlerts(companyId: string) {
  const { data, error } = await supabase.from('management_alerts').select('*').eq('company_id', companyId).order('reference_at')
  if (error) throw error
  return data ?? []
}

export async function getCrmFunnel(companyId: string) {
  const { data, error } = await supabase.from('management_crm_funnel').select('*').eq('company_id', companyId)
  if (error) throw error
  return data ?? []
}
