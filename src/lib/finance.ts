import { supabase } from '@/integrations/supabase/client'

export type FinancialStatus = 'pendente' | 'parcial' | 'pago' | 'vencido' | 'cancelado'

export async function listFinancialEntries(companyId: string) {
  const { data, error } = await supabase.from('financial_entry_balances').select('*').eq('company_id', companyId).order('due_date')
  if (error) throw error
  return data ?? []
}

export async function registerPayment(entryId: string, amount: number, accountId?: string, method?: string, reference?: string) {
  const { data, error } = await supabase.rpc('register_financial_payment', {
    target_entry_id: entryId,
    payment_amount: amount,
    target_account_id: accountId ?? null,
    target_method: method ?? null,
    target_reference: reference ?? null,
  })
  if (error) throw error
  return data as string
}

export async function createContractReceivables(contractId: string, options: {
  depositAmount?: number
  depositDue?: string
  balanceDue?: string
  securityDepositAmount?: number
} = {}) {
  const { data, error } = await supabase.rpc('create_contract_receivables', {
    target_contract_id: contractId,
    deposit_amount: options.depositAmount ?? 0,
    deposit_due: options.depositDue ?? new Date().toISOString().slice(0,10),
    balance_due: options.balanceDue ?? null,
    security_deposit_amount: options.securityDepositAmount ?? 0,
  })
  if (error) throw error
  return Number(data ?? 0)
}

export async function refundSecurityDeposit(entryId: string, accountId?: string) {
  const { data, error } = await supabase.rpc('refund_security_deposit', { target_entry_id: entryId, target_account_id: accountId ?? null })
  if (error) throw error
  return data as string
}

export async function listCashMovements(companyId: string, from?: string, until?: string) {
  let query = supabase.from('cash_movements').select('*').eq('company_id', companyId)
  if (from) query = query.gte('paid_at', from)
  if (until) query = query.lte('paid_at', until)
  const { data, error } = await query.order('paid_at', { ascending: false })
  if (error) throw error
  return data ?? []
}
