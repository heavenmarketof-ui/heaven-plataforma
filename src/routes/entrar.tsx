import { createFileRoute, Link, useNavigate } from '@tanstack/react-router'
import { useState } from 'react'
import { supabase } from '../integrations/supabase/client'

export const Route = createFileRoute('/entrar')({ component: LoginPage })

function LoginPage() {
  const navigate = useNavigate(); const [loading,setLoading]=useState(false); const [error,setError]=useState('')
  async function login(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault(); setLoading(true); setError('')
    const form=new FormData(event.currentTarget); const email=String(form.get('email')||'').trim().toLowerCase(); const password=String(form.get('password')||'')
    const { error: loginError }=await supabase.auth.signInWithPassword({email,password})
    if(loginError){setError('E-mail ou senha inválidos, ou seu e-mail ainda não foi confirmado.');setLoading(false);return}
    const { error: activationError }=await supabase.rpc('activate_my_pending_trial')
    if(activationError){setError('Seu acesso foi confirmado, mas não conseguimos ativar o ambiente automaticamente. Tente entrar novamente.');setLoading(false);return}
    navigate({to:'/app'})
  }
  return <div className="landing"><div className="trial-wrap"><div className="trial-card login-card"><Link to="/" className="back">← Início</Link><div className="brand">heaven <small>PLATAFORMA</small></div><span className="tag">Acesso seguro</span><h1>Entre na sua Heaven</h1><p>Use o e-mail confirmado para acessar ou ativar o ambiente da sua empresa.</p><form className="trial-form" onSubmit={login}><label>E-mail<input required name="email" type="email" autoComplete="email" /></label><label>Senha<input required name="password" type="password" autoComplete="current-password" /></label>{error&&<div className="form-error">{error}</div>}<button className="primary" disabled={loading}>{loading?'Entrando...':'Entrar'}</button></form><p className="login-help">Ainda não tem uma conta? <Link to="/testar">Teste grátis por 15 dias.</Link></p></div><aside className="price-card"><span>Seu ambiente Heaven</span><strong>Uma empresa.<br/>Dados isolados.</strong><p>CRM, contratos, agenda, estoque, produção, logística e financeiro conectados em um único fluxo.</p><hr/><b>O período gratuito começa somente quando seu ambiente é ativado.</b></aside></div></div>
}
