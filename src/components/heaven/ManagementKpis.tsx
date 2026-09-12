import type { ManagementSummary } from '@/lib/management'

const money = new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'})

export function ManagementKpis({ data }: { data: ManagementSummary }) {
  const cards = [
    ['Vendas do período', money.format(data.sales_total), `${data.sales_count} venda(s)`],
    ['Eventos do período', money.format(data.event_total), `${data.event_count} evento(s)`],
    ['Ticket médio', money.format(data.average_ticket), 'vendas ÷ quantidade'],
    ['Recebido', money.format(data.received), 'caixa realizado'],
    ['Pago', money.format(data.paid), 'caixa realizado'],
    ['Caixa operacional', money.format(data.operating_cash), 'caução excluída'],
    ['Inadimplência', money.format(data.overdue_receivable), 'recebimentos vencidos'],
    ['Conversão CRM', `${data.conversion_rate}%`, `${data.won_count} de ${data.leads_count} leads`],
  ]

  return <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
    {cards.map(([title,value,caption]) => <article key={title} className="rounded-xl border bg-card p-4 shadow-sm">
      <p className="text-sm text-muted-foreground">{title}</p>
      <strong className="mt-2 block text-2xl">{value}</strong>
      <span className="text-xs text-muted-foreground">{caption}</span>
    </article>)}
  </div>
}
