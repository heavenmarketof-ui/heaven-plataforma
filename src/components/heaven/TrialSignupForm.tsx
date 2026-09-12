import { useState } from 'react'

type TrialSignupFormProps = {
  compact?: boolean
}

export function TrialSignupForm({ compact = false }: TrialSignupFormProps) {
  const [sent, setSent] = useState(false)

  if (sent) {
    return (
      <div className="trial-success">
        <strong>Cadastro recebido</strong>
        <p>O próximo passo será confirmar seu e-mail e ativar o ambiente da empresa. Os 15 dias começam na ativação.</p>
      </div>
    )
  }

  return (
    <form
      className={`trial-form${compact ? ' trial-form-compact' : ''}`}
      onSubmit={(event) => {
        event.preventDefault()
        setSent(true)
      }}
    >
      <label>
        Seu nome
        <input required name="name" autoComplete="name" placeholder="Nome completo" />
      </label>
      <label>
        Nome da empresa
        <input required name="companyName" autoComplete="organization" placeholder="Ex.: Encanto Festas" />
      </label>
      <div className="form-grid">
        <label>
          WhatsApp
          <input required name="phone" inputMode="tel" autoComplete="tel" placeholder="(11) 99999-9999" />
        </label>
        <label>
          E-mail
          <input required name="email" type="email" autoComplete="email" placeholder="voce@empresa.com" />
        </label>
      </div>
      {!compact && (
        <div className="form-grid">
          <label>
            Cidade
            <input required name="city" autoComplete="address-level2" placeholder="Sua cidade" />
          </label>
          <label>
            UF
            <input required name="state" autoComplete="address-level1" maxLength={2} placeholder="SP" />
          </label>
        </div>
      )}
      <label>
        Senha
        <input required name="password" type="password" minLength={8} autoComplete="new-password" placeholder="Mínimo de 8 caracteres" />
      </label>
      <button className="primary" type="submit">Começar meus 15 dias grátis</button>
      <small className="legal">Sem cobrança para iniciar. Após os 15 dias, a continuidade exige implantação e ativação de R$ 1.000,00 + mensalidade de R$ 99,90.</small>
    </form>
  )
}
