import type { ReactNode } from 'react'
import type { ActiveCompanyContext } from '@/lib/company-context'

interface AppShellProps {
  company: ActiveCompanyContext
  children: ReactNode
}

const navigation = [
  'Hoje',
  'CRM e Leads',
  'Clientes',
  'Orçamentos',
  'Contratos',
  'Agenda e Eventos',
  'Estoque',
  'Logística',
  'Financeiro',
  'Gestão',
  'Configurações',
]

export function AppShell({ company, children }: AppShellProps) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <aside className="fixed inset-y-0 left-0 hidden w-64 border-r bg-card p-5 lg:block">
        <div className="mb-8">
          <p className="text-xs font-medium uppercase tracking-[0.22em] text-muted-foreground">Heaven</p>
          <h1 className="text-xl font-semibold">{company.companyName}</h1>
          <p className="text-sm text-muted-foreground">{company.role}</p>
        </div>
        <nav className="space-y-1">
          {navigation.map((item) => (
            <button key={item} className="w-full rounded-lg px-3 py-2 text-left text-sm hover:bg-muted">
              {item}
            </button>
          ))}
        </nav>
      </aside>
      <main className="min-h-screen lg:pl-64">
        <header className="flex h-16 items-center justify-between border-b bg-card px-5">
          <div>
            <p className="font-medium">Heaven Plataforma</p>
            <p className="text-xs text-muted-foreground">Operação da sua empresa em um só lugar</p>
          </div>
        </header>
        <div className="p-5 lg:p-8">{children}</div>
      </main>
    </div>
  )
}
