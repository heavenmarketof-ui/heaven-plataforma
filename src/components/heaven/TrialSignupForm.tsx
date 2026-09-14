import { useState, type FormEvent } from 'react'
import { useNavigate } from '@tanstack/react-router'
import { supabase, supabaseConfigured, supabaseProjectHost } from '../../integrations/supabase/client'

type TrialSignupFormProps = { compact?: boolean }

type Status = 'idle' | 'loading' | 'sent'

function friendlyError(error: unknown) {
  if (error instanceof Error) return error.message
  return 'Erro inesperado ao conectar com o serviço de cadastro.'
}

export function TrialSignupForm({ compact = false }: TrialSignupFormProps) {
  const navigate = useNavigate()
  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState('')

  if (status === 'sent') {
    return (
      <div className="trial-success">
        <strong>Confira seu e-mail</strong>
        <p>Seu cadastro foi recebido. Enviamos a confirmação para ativar o ambiente Heaven de 15 dias.</p>
      </div>
    )
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError('')

    const formElement = event.currentTarget
    if (!formElement.reportValidity()) return

    if (!supabaseConfigured) {
      setError('A conexão com o cadastro não está configurada nesta implantação. Atualize a implantação e tente novamente.')
      console.error('[Heaven signup] Supabase indisponível no build.')
      return
    }

    const form = new FormData(formElement)
    const name = String(form.get('name') || '').trim()
    const companyName = String(form.get('companyName') || '').trim()
    const phone = String(form.get('phone') || '').trim()
    const email = String(form.get('email') || '').trim().toLowerCase()
    const city = String(form.get('city') || '').trim()
    const state = String(form.get('state') || '').trim().toUpperCase()
    const password = String(form.get('password') || '')

    if (!name || !companyName || !phone || !email || (!compact && (!city || !state)) || password.length < 8) {
      setError('Revise os campos obrigatórios e tente novamente.')
      return
    }

    setStatus('loading')
    const redirect = `${window.location.origin}/ativar`

    try {
      console.info(`[Heaven signup] Enviando cadastro para ${supabaseProjectHost}`)
      const { data, error: signUpError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: redirect,
          data: {
            full_name: name,
            company_name: companyName,
            phone,
            ...(city ? { city } : {}),
            ...(state ? { state } : {}),
            signup_source: 'website',
            heaven_trial_signup: true,
          },
        },
      })

      if (signUpError) throw signUpError
      if (!data.user) throw new Error('O serviço de cadastro não retornou um usuário. Tente novamente.')

      console.info('[Heaven signup] Usuário criado; aguardando confirmação/ativação.')

      if (data.session) {
        const activation = await supabase.rpc('activate_my_pending_trial')
        if (activation.error) throw activation.error
        navigate({ to: '/app' })
        return
      }

      setStatus('sent')
    } catch (caught) {
      console.error('[Heaven signup] Falha no cadastro:', caught)
      setError(friendlyError(caught))
      setStatus('idle')
    }
  }

  return (
    <form className={`trial-form${compact ? ' trial-form-compact' : ''}`} onSubmit={handleSubmit}>
      <label>Seu nome<input required name="name" autoComplete="name" placeholder="Nome completo" /></label>
      <label>Nome da empresa<input required name="companyName" autoComplete="organization" placeholder="Ex.: Encanto Festas" /></label>
      <div className="form-grid">
        <label>WhatsApp<input required name="phone" inputMode="tel" autoComplete="tel" placeholder="(11) 99999-9999" /></label>
        <label>E-mail<input required name="email" type="email" autoComplete="email" placeholder="voce@empresa.com" /></label>
      </div>
      {!compact && <div className="form-grid">
        <label>Cidade<input required name="city" autoComplete="address-level2" placeholder="Sua cidade" /></label>
        <label>UF<input required name="state" autoComplete="address-level1" minLength={2} maxLength={2} placeholder="SP" /></label>
      </div>}
      <label>Senha<input required name="password" type="password" minLength={8} autoComplete="new-password" placeholder="Mínimo de 8 caracteres" /></label>
      {error && <div className="form-error" role="alert">Não foi possível concluir o cadastro: {error}</div>}
      <button className="primary" type="submit" disabled={status === 'loading'}>{status === 'loading' ? 'Criando cadastro...' : 'Começar meus 15 dias grátis'}</button>
      <small className="legal">Sem cobrança para iniciar. Após os 15 dias, a continuidade exige implantação e ativação de R$ 1.000,00 + mensalidade de R$ 99,90.</small>
    </form>
  )
}
