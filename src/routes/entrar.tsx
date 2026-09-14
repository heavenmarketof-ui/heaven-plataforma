import { createFileRoute, Link, useNavigate } from '@tanstack/react-router'
import { useState, type FormEvent } from 'react'
import { supabase } from '../integrations/supabase/client'

export const Route = createFileRoute('/entrar')({ component: LoginPage })

function LoginPage() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function login(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setLoading(true)
    setError('')

    const form = new FormData(event.currentTarget)
    const email = String(form.get('email') || '').trim().toLowerCase()
    const password = String(form.get('password') || '')

    try {
      const { error: loginError } = await supabase.auth.signInWithPassword({ email, password })
      if (loginError) throw new Error('E-mail ou senha inválidos, ou seu e-mail ainda não foi confirmado.')

      const activation = await supabase.rpc('activate_my_pending_trial')
      if (activation.error) {
        console.error('[Heaven login] Falha ao ativar trial:', activation.error)
        throw new Error(`Seu acesso foi confirmado, mas não conseguimos ativar sua empresa: ${activation.error.message}`)
      }

      const context = await supabase.rpc('my_company_context')
      if (context.error) {
        console.error('[Heaven login] Falha ao carregar contexto:', context.error)
        throw new Error(`Sua empresa foi ativada, mas não conseguimos carregar o ambiente: ${context.error.message}`)
      }

      const rows = Array.isArray(context.data) ? context.data : context.data ? [context.data] : []
      if (!rows.length) throw new Error('Sua conta está confirmada, mas nenhum ambiente Heaven foi encontrado.')

      navigate({ to: '/app' })
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Não foi possível entrar na Heaven.')
      setLoading(false)
    }
  }

  return (
    <div className="landing">
      <div className="trial-wrap">
        <div className="trial-card login-card">
          <Link to="/" className="back">← Início</Link>
          <div className="brand">heaven <small>PLATAFORMA</small></div>
          <span className="tag">Acesso seguro</span>
          <h1>Entre na sua Heaven</h1>
          <p>Use o e-mail confirmado para acessar sua empresa.</p>
          <form className="trial-form" onSubmit={login}>
            <label>E-mail<input required name="email" type="email" autoComplete="email" /></label>
            <label>Senha<input required name="password" type="password" autoComplete="current-password" /></label>
            {error && <div className="form-error" role="alert">{error}</div>}
            <button className="primary" disabled={loading}>{loading ? 'Preparando sua Heaven...' : 'Entrar'}</button>
            <Link to="/recuperar-senha">Esqueci minha senha</Link>
          </form>
          <p className="login-help">Ainda não tem uma conta? <Link to="/testar">Teste grátis por 15 dias.</Link></p>
        </div>
        <aside className="price-card">
          <span>Seu ambiente Heaven</span>
          <strong>Uma empresa.<br />Dados isolados.</strong>
          <p>CRM, contratos, agenda, estoque, operação e financeiro conectados.</p>
          <hr />
          <b>O período gratuito começa somente quando seu ambiente é ativado.</b>
        </aside>
      </div>
    </div>
  )
}
