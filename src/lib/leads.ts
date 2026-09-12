import { supabase } from '@/integrations/supabase/client'

export type LeadStatus = 'novo' | 'em_atendimento' | 'orcamento' | 'negociacao' | 'ganho' | 'perdido'

export interface Lead {
  id: string
  company_id: string
  assigned_user_id: string | null
  name: string
  phone: string | null
  email: string | null
  source: string | null
  event_type: string | null
  event_date: string | null
  city: string | null
  notes?: string | null
  status: LeadStatus
  next_action_at: string | null
  created_at: string
}

export async function listActionableLeads(companyId: string) {
  const { data, error } = await supabase
    .from('actionable_leads')
    .select('*')
    .eq('company_id', companyId)
    .order('created_at', { ascending: false })

  if (error) throw error
  return (data ?? []) as Lead[]
}

export async function startLeadAttendance(leadId: string) {
  const { error } = await supabase
    .from('leads')
    .update({ status: 'em_atendimento', first_contact_at: new Date().toISOString() })
    .eq('id', leadId)
    .eq('status', 'novo')

  if (error) throw error
}

export function buildWhatsAppUrl(phone: string | null, customerName?: string) {
  if (!phone) return null
  const digits = phone.replace(/\D/g, '')
  if (!digits) return null
  const normalized = digits.startsWith('55') ? digits : `55${digits}`
  const message = customerName ? `Olá, ${customerName}! Tudo bem?` : 'Olá! Tudo bem?'
  return `https://wa.me/${normalized}?text=${encodeURIComponent(message)}`
}
