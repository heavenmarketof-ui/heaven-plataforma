import { supabase } from '@/integrations/supabase/client'

export type CompanyRole = 'proprietario' | 'administrador' | 'gerente' | 'equipe'

export interface ActiveCompanyContext {
  companyId: string
  companyName: string
  role: CompanyRole
}

export async function getActiveCompanyContext(userId: string): Promise<ActiveCompanyContext | null> {
  const { data, error } = await supabase
    .from('company_members')
    .select('company_id, role, companies!inner(id, name, status)')
    .eq('user_id', userId)
    .eq('active', true)
    .eq('companies.status', 'ativa')
    .limit(1)
    .maybeSingle()

  if (error) throw error
  if (!data) return null

  const company = Array.isArray(data.companies) ? data.companies[0] : data.companies
  if (!company) return null

  return {
    companyId: data.company_id,
    companyName: company.name,
    role: data.role as CompanyRole,
  }
}
