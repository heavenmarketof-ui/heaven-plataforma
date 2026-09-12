import { supabase } from '@/integrations/supabase/client'

export type QuoteStatus = 'rascunho' | 'enviado' | 'aprovado' | 'recusado' | 'expirado' | 'cancelado'

export interface Quote {
  id: string
  company_id: string
  lead_id: string | null
  client_id: string | null
  title: string
  event_type: string | null
  event_date: string | null
  status: QuoteStatus
  subtotal: number
  discount: number
  total: number
  valid_until: string | null
}

export async function listQuotes(companyId: string) {
  const { data, error } = await supabase.from('quotes').select('*').eq('company_id', companyId).order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []) as Quote[]
}

export async function setQuoteStatus(quoteId: string, status: QuoteStatus) {
  const patch: Record<string, unknown> = { status, updated_at: new Date().toISOString() }
  if (status === 'enviado') patch.sent_at = new Date().toISOString()
  if (status === 'aprovado') patch.approved_at = new Date().toISOString()
  const { error } = await supabase.from('quotes').update(patch).eq('id', quoteId)
  if (error) throw error
}

export async function createContractFromQuote(quoteId: string) {
  const { data, error } = await supabase.rpc('create_contract_from_quote', { target_quote_id: quoteId })
  if (error) throw error
  return data as string
}
