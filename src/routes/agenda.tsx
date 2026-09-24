import { createFileRoute, Link } from '@tanstack/react-router'
export const Route = createFileRoute('/agenda')({ component: Agenda })
function Agenda() {
  return (
    <div className="app-gate">
      <div>
        <img src="/heaven-logo.svg" alt="Heaven ERP" style={{ width: 220 }} />
        <h1>Agenda e Eventos</h1>
        <p>Agenda carregada com sucesso.</p>
        <Link to="/app" className="primary-link">Voltar</Link>
      </div>
    </div>
  )
}
