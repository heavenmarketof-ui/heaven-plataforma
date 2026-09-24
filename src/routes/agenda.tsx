import { createFileRoute, Link, useNavigate } from '@tanstack/react-router'
import { useEffect, useMemo, useState } from 'react'
import { supabase } from '../integrations/supabase/client'
import { loadCommercialData, reserveInventory, shortDate } from '../lib/erp-data'
import { canAccess, canWrite, roleLabel } from '../lib/permissions'

export const Route = createFileRoute('/agenda')({ component: Agenda })

type Row = Record<string, any>
type Context = { company_id: string; company_name: string; role: string; access_allowed: boolean }

const labels: Record<string, string> = {
  planejado: 'Planejado',
  confirmado: 'Confirmado',
  em_preparacao: 'Em preparação',
  em_execucao: 'Em execução',
  aguardando_devolucao: 'Aguardando devolução',
  finalizado: 'Finalizado',
  cancelado: 'Cancelado',
}

function Agenda() {
  const navigate = useNavigate()
  const [ctx, setCtx] = useState<Context | null>(null)
  const [data, setData] = useState<any>({ events: [], clients: [], tasks: [], reservations: [] })
  const [error, setError] = useState('')
  const [month, setMonth] = useState(() => new Date().toISOString().slice(0, 7))
  const [selected, setSelected] = useState<Row | null>(null)\n  const [reserving, setReserving] = useState(false)\n  const [busy, setBusy] = useState(false)

  useEffect(() => {
    void (async () => {
      const { data: auth } = await supabase.auth.getUser()
      if (!auth.user) {
        navigate({ to: '/entrar' })
        return
      }
      const result = await supabase.rpc('my_company_context')
      if (result.error) {
        setError(result.error.message)
        return
      }
      const context = (Array.isArray(result.data) ? result.data[0] : result.data) as Context
      setCtx(context)
      if (!context?.access_allowed || !canAccess(context.role, 'comercial')) return
      try {
        setData(await loadCommercialData())
      } catch (e: any) {
        setError(e.message || 'Não foi possível carregar a agenda.')
      }
    })()
  }, [navigate])

  const events = useMemo(
    () => data.events.filter((event: Row) => String(event.event_date || '').startsWith(month)),
    [data.events, month],
  )

  const days = useMemo(() => {
    const [year, monthNumber] = month.split('-').map(Number)
    const first = new Date(year, monthNumber - 1, 1)
    const count = new Date(year, monthNumber, 0).getDate()
    const result: Array<number | null> = []
    for (let i = 0; i < first.getDay(); i += 1) result.push(null)
    for (let day = 1; day <= count; day += 1) result.push(day)
    while (result.length % 7) result.push(null)
    return result
  }, [month])

  if (!ctx) return <Gate text={error || 'Carregando agenda...'} />
  if (!ctx.access_allowed || !canAccess(ctx.role, 'comercial')) {
    return <Gate text="Seu perfil não possui acesso à agenda." />
  }

  const write = canWrite(ctx.role, 'comercial')\n  const today = new Date().toISOString().slice(0, 10)
  const upcoming = data.events
    .filter((event: Row) => event.event_date >= today && !['finalizado', 'cancelado'].includes(event.status))
    .sort((a: Row, b: Row) => String(a.event_date).localeCompare(String(b.event_date)))

  return (
    <div className="heaven-shell">
      <aside className="heaven-sidebar erp-sidebar">
        <Link to="/app" className="erp-sidebar-logo"><img src="/heaven-logo.svg" alt="Heaven ERP" /></Link>
        <div className="erp-menu-label">COMERCIAL</div>
        <nav className="heaven-nav erp-nav">
          <Link to="/app"><i>⌂</i><span>Visão geral</span></Link>
          <Link to="/comercial"><i>◎</i><span>CRM e Comercial</span></Link>
          <b className="active erp-static"><i>□</i><span>Agenda e Eventos</span></b>
          {canAccess(ctx.role, 'operacao') && <Link to="/operacoes"><i>✓</i><span>Produção e Logística</span></Link>}
          {canAccess(ctx.role, 'operacao') && <Link to="/acervo"><i>◇</i><span>Acervo</span></Link>}
          {canAccess(ctx.role, 'financeiro') && <Link to="/financeiro"><i>R$</i><span>Financeiro</span></Link>}
          {canAccess(ctx.role, 'fiscal') && <Link to="/fiscal"><i>NF</i><span>Notas Fiscais</span></Link>}
          {canAccess(ctx.role, 'configuracoes') && <Link to="/configuracoes"><i>⚙</i><span>Configurações</span></Link>}
        </nav>
        <div className="heaven-company erp-company"><span className="erp-avatar">{ctx.company_name?.[0] || 'H'}</span><div><b>{ctx.company_name}</b><small>{roleLabel(ctx.role)}</small></div></div>
      </aside>

      <main className="heaven-main erp-main">
        <header className="heaven-header erp-header">
          <div><span className="heaven-eyebrow">{ctx.company_name}</span><h1 className="heaven-title">Agenda e Eventos</h1><span className="heaven-muted">Calendário operacional das festas e locações.</span></div>
          <input className="agenda-month" type="month" value={month} onChange={(e) => setMonth(e.target.value)} />
        </header>

        {error && <div className="heaven-alert">{error}<button onClick={() => setError('')}>×</button></div>}

        <div className="heaven-grid heaven-kpis erp-kpis">
          <K value={events.length} label="Eventos no mês" />
          <K value={events.filter((event: Row) => event.event_date === today).length} label="Eventos hoje" />
          <K value={upcoming.length} label="Próximos eventos" />
          <K value={data.tasks.filter((task: Row) => !task.completed_at).length} label="Tarefas pendentes" />
        </div>

        <section className="heaven-card agenda-card">
          <div className="agenda-weekdays">{['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'].map((name) => <b key={name}>{name}</b>)}</div>
          <div className="agenda-calendar">
            {days.map((day, index) => {
              const date = day ? month + '-' + String(day).padStart(2, '0') : ''
              const items = day ? events.filter((event: Row) => event.event_date === date) : []
              return (
                <div className={'agenda-day ' + (date === today ? 'today' : '') + (!day ? ' blank' : '')} key={index}>
                  {day && <span className="agenda-day-number">{day}</span>}
                  {items.slice(0, 3).map((event: Row) => (
                    <button className={'agenda-chip ' + event.status} key={event.id} onClick={() => setSelected(event)}>
                      <b>{event.event_time?.slice(0, 5) || 'Evento'}</b><span>{event.title}</span>
                    </button>
                  ))}
                  {items.length > 3 && <small>+ {items.length - 3} evento(s)</small>}
                </div>
              )
            })}
          </div>
        </section>

        <section className="heaven-card module-card">
          <div className="card-head"><div><span className="erp-section-kicker">PRÓXIMOS</span><h2>Eventos programados</h2></div><Link to="/operacoes">Abrir produção</Link></div>
          {upcoming.slice(0, 8).map((event: Row) => {
            const client = data.clients.find((item: Row) => item.id === event.client_id)
            return <button className="agenda-list-event" key={event.id} onClick={() => setSelected(event)}><div className="erp-date"><b>{String(event.event_date).slice(8, 10)}</b><span>{String(event.event_date).slice(5, 7)}</span></div><div><b>{event.title}</b><small>{client?.name || 'Cliente'} · {event.city || 'Local a definir'}</small></div><em className="heaven-status">{labels[event.status] || event.status}</em></button>
          })}
          {!upcoming.length && <p className="heaven-muted">Nenhum próximo evento cadastrado.</p>}
        </section>
      </main>

      {selected && <EventSummary event={selected} data={data} write={write} reserving={reserving} busy={busy} close={() => { setSelected(null); setReserving(false) }} startReserve={() => setReserving(true)} saveReserve={async (itemId, quantity) => {\n        setBusy(true)\n        setError('')\n        try {\n          const start = new Date(selected.event_date + 'T00:00:00').toISOString()\n          const end = new Date(selected.event_date + 'T23:59:59').toISOString()\n          await reserveInventory(ctx.company_id, selected.id, itemId, quantity, start, end)\n          setData(await loadCommercialData())\n          setReserving(false)\n        } catch (e: any) {\n          setError(e.message || 'Não foi possível reservar a peça.')\n        } finally { setBusy(false) }\n      }} />}
    </div>
  )
}

function EventSummary({ event, data, write, reserving, busy, close, startReserve, saveReserve }: { event: Row; data: any; write: boolean; reserving: boolean; busy: boolean; close: () => void; startReserve: () => void; saveReserve: (itemId: string, quantity: number) => Promise<void> }) {
  const client = data.clients.find((item: Row) => item.id === event.client_id)
  const tasks = data.tasks.filter((item: Row) => item.event_id === event.id && !item.completed_at)
  const reservations = data.reservations.filter((item: Row) => item.event_id === event.id)
  return (
    <div className="drawer-backdrop" onMouseDown={close}>
      <aside className="event-drawer" onMouseDown={(e) => e.stopPropagation()}>
        <div className="card-head"><div><span className="erp-section-kicker">EVENTO</span><h2>{event.title}</h2></div><button onClick={close}>×</button></div>
        <div className="event-drawer-status"><span className="heaven-status">{labels[event.status] || event.status}</span><b>{shortDate(event.event_date)} {event.event_time?.slice(0, 5) || ''}</b></div>
        <div className="event-detail-grid"><D label="Cliente" value={client?.name || 'Não vinculado'} /><D label="Local" value={[event.address, event.city, event.state].filter(Boolean).join(' · ') || 'A definir'} /><D label="Reservas" value={String(reservations.length)} /><D label="Tarefas abertas" value={String(tasks.length)} /></div>
        <h3>Acervo reservado</h3>\n        {reservations.map((reservation: Row) => { const item = data.inventory.find((x: Row) => x.id === reservation.item_id); return <div className="heaven-task" key={reservation.id}><div><b>{item?.name || 'Peça'}</b><small>{reservation.quantity} unidade(s)</small></div></div> })}\n        {!reservations.length && <p className="heaven-muted">Nenhuma peça reservada.</p>}\n        {write && !reserving && <button className="primary drawer-action" onClick={startReserve}>+ Reservar peça</button>}\n        {write && reserving && <form className="trial-form drawer-form" onSubmit={(e) => { e.preventDefault(); const form = new FormData(e.currentTarget); void saveReserve(String(form.get('itemId') || ''), Number(form.get('quantity') || 1)) }}><label>Peça<select name="itemId" required>{data.inventory.map((item: Row) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label><label>Quantidade<input name="quantity" type="number" min="1" defaultValue="1" required /></label><button className="primary" disabled={busy}>{busy ? 'Reservando...' : 'Confirmar reserva'}</button></form>}\n        <div className="drawer-links"><Link to="/operacoes">Produção e devolução</Link><Link to="/acervo">Consultar acervo</Link><Link to="/financeiro">Financeiro</Link></div>
      </aside>
    </div>
  )
}

function K({ value, label }: { value: number; label: string }) { return <div className="heaven-card erp-kpi"><small>{label}</small><div className="heaven-value">{value}</div></div> }
function D({ label, value }: { label: string; value: string }) { return <div><small>{label}</small><b>{value}</b></div> }
function Gate({ text }: { text: string }) { return <div className="app-gate"><div><img src="/heaven-logo.svg" alt="Heaven ERP" style={{ width: 220 }} /><p>{text}</p><Link to="/app" className="primary-link">Voltar</Link></div></div> }
