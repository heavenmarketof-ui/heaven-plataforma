import { createFileRoute, Link } from '@tanstack/react-router'
import { TrialSignupForm } from '../components/heaven/TrialSignupForm'

export const Route = createFileRoute('/')({ component: Landing })

const features = [
  ['Comercial organizado', 'Leads, clientes, orçamentos e contratos conectados sem redigitar informações.'],
  ['Agenda sem conflito', 'Eventos, reservas e disponibilidade de estoque no mesmo fluxo.'],
  ['Operação sob controle', 'Separação, produção, entrega, montagem, devolução e conferência.'],
  ['Financeiro de verdade', 'Recebimentos, despesas, caixa, inadimplência e indicadores gerenciais.'],
]

function Landing() {
  return (
    <div className="landing">
      <header className="landing-header">
        <div className="brand">heaven <small>PLATAFORMA</small></div>
        <nav>
          <a href="#recursos">Recursos</a>
          <a href="#preco">Preço</a>
          <Link to="/demo">Ver demonstração</Link>
          <a href="#teste" className="nav-cta">Testar grátis</a>
        </nav>
      </header>
      <main>
        <section className="hero">
          <div>
            <span className="tag">ERP criado para o mercado de festas</span>
            <h1>Sua empresa de decoração organizada do primeiro contato à devolução.</h1>
            <p>Centralize comercial, contratos, agenda, estoque, produção, logística e financeiro em uma única plataforma.</p>
            <div className="hero-actions">
              <a href="#teste" className="primary-link">Testar grátis por 15 dias</a>
              <Link to="/demo" className="secondary-link">Conhecer o sistema</Link>
            </div>
            <small>Sem pagamento para começar.</small>
          </div>
          <div className="hero-panel">
            <div className="mini-top"><b>Hoje</b><span>3 ações importantes</span></div>
            <div className="mini-kpis"><div><small>Vendas</small><b>R$ 18.450</b></div><div><small>Eventos</small><b>9</b></div></div>
            <div className="mini-task"><span>●</span><div><b>Novo lead</b><small>Responder Mariana pelo WhatsApp</small></div></div>
            <div className="mini-task"><span>●</span><div><b>Separação pendente</b><small>Festa da Helena · 18/25 itens</small></div></div>
            <div className="mini-task"><span>●</span><div><b>Recebimento vencido</b><small>Contrato #1048 · R$ 480</small></div></div>
          </div>
        </section>
        <section id="recursos" className="features">
          <div className="section-title"><span className="tag">Uma plataforma, todo o fluxo</span><h2>Menos abas. Menos esquecimentos. Mais controle.</h2></div>
          <div className="feature-grid">{features.map(([title, description], index) => <article key={title}><span>0{index + 1}</span><h3>{title}</h3><p>{description}</p></article>)}</div>
        </section>
        <section id="preco" className="pricing">
          <div><span className="tag">Comece sem risco</span><h2>15 dias para testar a Heaven na sua rotina.</h2><p>Explore o sistema antes de decidir. Depois do período gratuito, contrate para continuar usando seu ambiente.</p></div>
          <div className="pricing-card"><span>Heaven Plataforma</span><div className="price"><b>R$ 1.000,00</b><small> implantação e ativação</small></div><div className="price plus-price">+ R$ 99,90 <small>/mês</small></div><ul><li>15 dias grátis</li><li>Todos os módulos da plataforma</li><li>Ambiente exclusivo da empresa</li><li>Atualizações contínuas</li></ul><a href="#teste" className="primary-link">Começar teste gratuito</a></div>
        </section>
        <section id="teste" className="home-trial">
          <div className="home-trial-copy">
            <span className="tag">Comece agora</span>
            <h2>Teste a Heaven por 15 dias dentro da sua empresa.</h2>
            <p>Cadastre sua empresa para iniciar o processo de criação do ambiente. O período gratuito começa quando o ambiente for ativado.</p>
            <div className="trial-price-note"><b>15 dias grátis</b><span>Depois: R$ 1.000,00 de implantação + R$ 99,90/mês.</span></div>
          </div>
          <div className="home-trial-form"><TrialSignupForm compact /></div>
        </section>
      </main>
      <footer><div className="brand">heaven <small>PLATAFORMA</small></div><p>Gestão para empresas de decoração e locação de festas.</p></footer>
    </div>
  )
}
