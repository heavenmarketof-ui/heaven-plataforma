export type CompanyRole = 'proprietario' | 'admin' | 'administrador' | 'gerente' | 'comercial' | 'operacao' | 'financeiro' | 'visualizador' | 'equipe'
export type Module = 'comercial' | 'operacao' | 'financeiro' | 'fiscal' | 'configuracoes' | 'equipe'

export const ROLE_LABELS: Record<CompanyRole,string>={proprietario:'Proprietário',admin:'Administrador',administrador:'Administrador',gerente:'Gerente',comercial:'Comercial',operacao:'Operação',financeiro:'Financeiro',visualizador:'Visualizador',equipe:'Equipe'}
const managers:CompanyRole[]=['proprietario','admin','administrador','gerente']
const access:Record<Module,CompanyRole[]>={
 comercial:[...managers,'comercial','visualizador'],
 operacao:[...managers,'comercial','operacao','visualizador','equipe'],
 financeiro:[...managers,'financeiro'],
 fiscal:[...managers,'financeiro'],
 configuracoes:['proprietario','admin','administrador'],
 equipe:['proprietario','admin','administrador'],
}
export function canAccess(role:string|null|undefined,module:Module){return !!role&&access[module].includes(role as CompanyRole)}
export function canWrite(role:string|null|undefined,module:Exclude<Module,'configuracoes'|'equipe'>){return canAccess(role,module)&&role!=='visualizador'}
export function canManageBusiness(role:string|null|undefined){return !!role&&managers.includes(role as CompanyRole)}
export function canManageTeam(role:string|null|undefined){return canAccess(role,'equipe')}
export function canManageSubscription(role:string|null|undefined){return role==='proprietario'}
export function roleLabel(role:string|null|undefined){return ROLE_LABELS[role as CompanyRole]||role||'Usuário'}
