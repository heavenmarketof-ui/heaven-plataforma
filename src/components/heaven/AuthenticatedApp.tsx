import { useEffect, useState, type ReactNode } from 'react'
import type { User } from '@supabase/supabase-js'
import { supabase } from '@/integrations/supabase/client'
import { getActiveCompanyContext, type ActiveCompanyContext } from '@/lib/company-context'
import { AppShell } from '@/components/heaven/AppShell'

export function AuthenticatedApp({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [company, setCompany] = useState<ActiveCompanyContext | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true

    async function hydrate() {
      const { data } = await supabase.auth.getUser()
      if (!active) return
      setUser(data.user)
      if (data.user) setCompany(await getActiveCompanyContext(data.user.id))
      setLoading(false)
    }

    hydrate().catch((error) => {
      console.error('[Heaven] Falha ao carregar sessão', error)
      if (active) setLoading(false)
    })

    const { data: subscription } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
      if (!session?.user) setCompany(null)
    })

    return () => {
      active = false
      subscription.subscription.unsubscribe()
    }
  }, [])

  if (loading) return <div className="grid min-h-screen place-items-center">Carregando Heaven...</div>

  if (!user) {
    return (
      <div className="grid min-h-screen place-items-center bg-muted/30 p-6">
        <div className="max-w-md rounded-2xl border bg-card p-8 text-center shadow-sm">
          <h1 className="text-2xl font-semibold">Heaven Plataforma</h1>
          <p className="mt-2 text-sm text-muted-foreground">Entre para acessar a operação da sua empresa.</p>
        </div>
      </div>
    )
  }

  if (!company) {
    return (
      <div className="grid min-h-screen place-items-center p-6">
        <div className="max-w-lg rounded-2xl border bg-card p-8">
          <h1 className="text-xl font-semibold">Configure sua empresa</h1>
          <p className="mt-2 text-sm text-muted-foreground">Sua conta está autenticada, mas ainda não possui uma empresa ativa vinculada. O onboarding será concluído no próximo passo.</p>
        </div>
      </div>
    )
  }

  return <AppShell company={company}>{children}</AppShell>
}
