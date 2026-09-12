import { createFileRoute, Link } from '@tanstack/react-router'
import { TrialSignupForm } from '../components/heaven/TrialSignupForm'

export const Route = createFileRoute('/testar')({ component: TrialPage })

function TrialPage() {
  return (
    <div className="landing">
      <div className="trial-wrap">
        <div className="trial-card">
          <Link to="/" className="back">← Início</Link>
          <div className="brand">heaven <small>PLATAFORMA</small></div>
          <span className="tag">15 dias grátis</span>
          <h1>Crie seu ambiente Heaven</h1>
          <p>Teste o ERP completo por 15 dias. Você não precisa pagar para começar.</p>
          <TrialSignupForm />
        </div>
        <aside className="price-card">
          <span>Após o período gratuito</span>
          <strong>R$ 1.000,00</strong>
          <p>implantação e ativação</p>
          <div className="plus">+</div>
          <strong>R$ 99,90 <small>/mês</small></strong>
          <p>mensalidade da plataforma</p>
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
