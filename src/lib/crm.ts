import { supabase } from '@/integrations/supabase/client'
import type { Lead, LeadStatus } from '@/lib/leads'

export const CRM_COLUMNS: Array<{ status: LeadStatus; label: string }> = [
  { status: 'novo', label: 'Novos' },
  { status: 'em_atendimento', label: 'Em atendimento' },
  { status: 'orcamento', label: 'Orçamento' },
  { status: 'negociacao', label: 'Negociação' },
  { status: 'ganho', label: 'Ganhos' },
  { status: 'perdido', label: 'Perdidos' },
]

export async function listLeads(companyId: string) {
  const { data, error } = await supabase
    .from('leads')
    .select('*')
    .eq('company_id', companyId)
    .order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []) as Lead[]
}

export async function createLead(companyId: string, input: Pick<Lead, 'name'> & Partial<Lead>) {
  const { data, error } = await supabase
    .from('leads')
    .insert({
      company_id: companyId,
      name: input.name.trim(),
      phone: input.phone || null,
      email: input.email || null,
      source: input.source || null,
      event_type: input.event_type || null,
      event_date: input.event_date || null,
      city: input.city || null,
      notes: input.notes || null,
      assigned_user_id: input.assigned_user_id || null,
    })
    .select('*')
    .single()
  if (error) throw error
  return data as Lead
}

export async function changeLeadStatus(leadId: string, status: LeadStatus) {
  const patch: Record<string, unknown> = { status, updated_at: new Date().toISOString() }
  if (status === 'ganho') patch.won_at = new Date().toISOString()
  if (status === 'perdido') patch.lost_at = new Date().toISOString()
  const { error } = await supabase.from('leads').update(patch).eq('id', leadId)
  if (error) throw error
}

export async function createQuoteFromLead(leadId: string) {
  const { data, error } = await supabase.rpc('create_quote_from_lead', { target_lead_id: leadId })
  if (error) throw error
  return data as string
}

export async function convertLeadToClient(leadId: string) {
  const { data, error } = await supabase.rpc('convert_lead_to_client', { target_lead_id: leadId })
  if (error) throw error
  return data as string
}
