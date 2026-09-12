export type CompanyRole = 'proprietario' | 'administrador' | 'gerente' | 'equipe'

export const ROLE_LABELS: Record<CompanyRole, string> = {
  proprietario: 'Proprietário',
  administrador: 'Administrador',
  gerente: 'Gerente',
  equipe: 'Equipe',
}

const roleWeight: Record<CompanyRole, number> = {
  equipe: 10,
  gerente: 20,
  administrador: 30,
  proprietario: 40,
}

export function hasMinimumRole(currentRole: CompanyRole | null | undefined, minimumRole: CompanyRole) {
  if (!currentRole) return false
  return roleWeight[currentRole] >= roleWeight[minimumRole]
}

export function canManageBusiness(currentRole: CompanyRole | null | undefined) {
  return hasMinimumRole(currentRole, 'gerente')
}

export function canManageTeam(currentRole: CompanyRole | null | undefined) {
  return hasMinimumRole(currentRole, 'administrador')
}

export function canManageSubscription(currentRole: CompanyRole | null | undefined) {
  return currentRole === 'proprietario'
}
