import { useEffect, useState, type ReactNode } from 'react'
import type { User } from '@supabase/supabase-js'
import { supabase } from '@/integrations/supabase/client'
import { getActiveCompanyContext, type ActiveCompanyContext } from '@/lib/company-context'
import { AppShell } from '@/components/heaven/AppShell'
import { CompanyOnboardingForm } from '@/components/heaven/CompanyOnboardingForm'

export function AuthenticatedApp({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [company, setCompany] = useState<ActiveCompanyContext | null>(null)
  const [loading, setLoading] = useState(true)

  async function hydrate(nextUser?: User | null) {
    setLoading(true)
    const resolvedUser = nextUser === undefined ? (await supabase.auth.getUser()).data.user : nextUser
    setUser(resolvedUser)
    setCompany(resolvedUser ? await getActiveCompanyContext(resolvedUser.id) : null)
    setLoading(false)
  }

  useEffect(() => {
    let active = true
    hydrate().catch((error) => {
      console.error('[Heaven] Falha ao carregar sessão', error)
      if (active) setLoading(false)
    })

    const { data: subscription } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!active) return
      hydrate(session?.user ?? null).catch((error) => console.error('[Heaven] Falha ao atualizar sessão', error))
    })

    return () => {
      active = false
      subscription.subscription.unsubscribe()
    }
  }, [])

  if (loading) return <div className="grid min-h-screen place-items-center">Carregando Heaven...</div>

  if (!user) {
    return <div className="grid min-h-screen place-items-center bg-muted/30 p-6"><div className="max-w-md rounded-2xl border bg-card p-8 text-center shadow-sm"><h1 className="text-2xl font-semibold">Heaven Plataforma</h1><p className="mt-2 text-sm text-muted-foreground">Entre para acessar a operação da sua empresa.</p></div></div>
  }

  if (!company) {
    return <div className="grid min-h-screen place-items-center bg-muted/20 p-6"><CompanyOnboardingForm onCreated={() => hydrate(user)} /></div>
  }

  return <AppShell company={company}>{children}</AppShell>
}
