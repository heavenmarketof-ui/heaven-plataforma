import { useState } from 'react'
import { supabase } from '../../integrations/supabase/client'

type TrialSignupFormProps = { compact?: boolean }

export function TrialSignupForm({ compact = false }: TrialSignupFormProps) {
  const [status, setStatus] = useState<'idle' | 'loading' | 'sent'>('idle')
  const [error, setError] = useState('')

  if (status === 'sent') return <div className="trial-success"><strong>Confira seu e-mail</strong><p>Enviamos a confirmação do seu cadastro. Depois de confirmar, entre na Heaven para ativar seu ambiente. Os 15 dias começam somente na ativação.</p></div>

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError(''); setStatus('loading')
    const form = new FormData(event.currentTarget)
    const name = String(form.get('name') || '').trim()
    const companyName = String(form.get('companyName') || '').trim()
    const phone = String(form.get('phone') || '').trim()
    const email = String(form.get('email') || '').trim().toLowerCase()
    const city = String(form.get('city') || '').trim()
    const state = String(form.get('state') || '').trim().toUpperCase()
    const password = String(form.get('password') || '')

    const { error: signUpError } = await supabase.auth.signUp({
      email, password,
      options: { data: { full_name: name, company_name: companyName, phone, city, state, heaven_trial_signup: true } },
    })
    if (signUpError) { setError(signUpError.message); setStatus('idle'); return }
    setStatus('sent')
  }

  return <form className={`trial-form${compact ? ' trial-form-compact' : ''}`} onSubmit={handleSubmit}>
    <label>Seu nome<input required name="name" autoComplete="name" placeholder="Nome completo" /></label>
    <label>Nome da empresa<input required name="companyName" autoComplete="organization" placeholder="Ex.: Encanto Festas" /></label>
    <div className="form-grid"><label>WhatsApp<input required name="phone" inputMode="tel" autoComplete="tel" placeholder="(11) 99999-9999" /></label><label>E-mail<input required name="email" type="email" autoComplete="email" placeholder="voce@empresa.com" /></label></div>
    {!compact && <div className="form-grid"><label>Cidade<input required name="city" autoComplete="address-level2" placeholder="Sua cidade" /></label><label>UF<input required name="state" autoComplete="address-level1" maxLength={2} placeholder="SP" /></label></div>}
    <label>Senha<input required name="password" type="password" minLength={8} autoComplete="new-password" placeholder="Mínimo de 8 caracteres" /></label>
    {error && <div className="form-error">Não foi possível concluir o cadastro: {error}</div>}
    <button className="primary" type="submit" disabled={status === 'loading'}>{status === 'loading' ? 'Criando cadastro...' : 'Começar meus 15 dias grátis'}</button>
    <small className="legal">Sem cobrança para iniciar. Após os 15 dias, a continuidade exige implantação e ativação de R$ 1.000,00 + mensalidade de R$ 99,90.</small>
  </form>
}
