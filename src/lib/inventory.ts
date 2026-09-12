import { supabase } from '@/integrations/supabase/client'

export interface InventoryItem {
  id: string
  company_id: string
  category_id: string | null
  sku: string | null
  name: string
  description: string | null
  total_quantity: number
  track_quantity: boolean
  status: 'ativo' | 'manutencao' | 'inativo'
  replacement_cost: number | null
}

export async function listInventory(companyId: string) {
  const { data, error } = await supabase.from('inventory_items').select('*').eq('company_id', companyId).order('name')
  if (error) throw error
  return (data ?? []) as InventoryItem[]
}

export async function getAvailability(companyId: string, itemId: string, from: string, until: string, ignoreEventId?: string) {
  const { data, error } = await supabase.rpc('inventory_availability', {
    target_company_id: companyId,
    target_item_id: itemId,
    period_from: from,
    period_until: until,
    ignore_event_id: ignoreEventId ?? null,
  })
  if (error) throw error
  return Number(data ?? 0)
}

export async function reserveInventory(eventId: string, itemId: string, quantity: number, from: string, until: string) {
  const { data, error } = await supabase.rpc('reserve_inventory_item', {
    target_event_id: eventId,
    target_item_id: itemId,
    requested_quantity: quantity,
    period_from: from,
    period_until: until,
  })
  if (error) throw error
  return data as string
}

export async function prepareInventoryChecklist(eventId: string, phase: 'separacao' | 'devolucao') {
  const { data, error } = await supabase.rpc('prepare_event_inventory_check', { target_event_id: eventId, target_phase: phase })
  if (error) throw error
  return Number(data ?? 0)
}

export async function listInventoryConflicts(companyId: string) {
  const { data, error } = await supabase.from('inventory_conflicts').select('*').eq('company_id', companyId)
  if (error) throw error
  return data ?? []
}
