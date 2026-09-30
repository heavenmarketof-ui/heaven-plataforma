import { createFileRoute, Link } from '@tanstack/react-router'
import { TrialSignupForm } from '../components/heaven/TrialSignupForm'

export const Route = createFileRoute('/testar')({ component: TrialPage })

function TrialPage() {
  return (
    <div className="landing">
      <div className="trial-wrap">
        <div className="trial-card">
          <Link to="/" className="back">← Início</Link>
          <img src="/heaven-logo.svg" alt="Heaven ERP" className="trial-logo"/>
          <span className="tag">15 dias grátis</span>
          <h1>Crie seu ambiente Heaven</h1>
          <p>Teste o ERP completo por 15 dias. Você não precisa pagar para começar.</p>
          <TrialSignupForm />
        </div>
        <aside className="price-card">
          <span>Após o período gratuito</span>
          <strong>R$ 197</strong>
          <p>implantação única</p>
          <div className="plus">+</div>
          <strong>R$ 69,90 <small>/mês</small></strong>
          <p>condição Heaven Fundadoras por 12 meses</p>
          <hr />
          <ul>
            <li>CRM e orçamentos</li>
            <li>Contratos e agenda</li>
            <li>Estoque e reservas</li>
            <li>Produção e logística</li>
            <li>Financeiro e gestão</li>
          </ul>
          <b>Teste primeiro. Contrate somente se fizer sentido para sua empresa.</b>
        </aside>
      </div>
    </div>
  )
}
