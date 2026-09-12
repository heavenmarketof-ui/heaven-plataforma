import { useEffect, useMemo, useState } from 'react'
import type { ActiveCompanyContext } from '@/lib/company-context'
import type { Lead } from '@/lib/leads'
import { CRM_COLUMNS, changeLeadStatus, convertLeadToClient, createQuoteFromLead, listLeads } from '@/lib/crm'

export function LeadsKanban({ company }: { company: ActiveCompanyContext }) {
  const [leads, setLeads] = useState<Lead[]>([])
  const [loading, setLoading] = useState(true)
  const [busyId, setBusyId] = useState<string | null>(null)

  async function reload() {
    setLeads(await listLeads(company.companyId))
  }

  useEffect(() => {
    let active = true
    listLeads(company.companyId)
      .then((data) => active && setLeads(data))
      .finally(() => active && setLoading(false))
    return () => { active = false }
  }, [company.companyId])

  const grouped = useMemo(() => Object.fromEntries(CRM_COLUMNS.map((column) => [column.status, leads.filter((lead) => lead.status === column.status)])), [leads])

  async function createQuote(lead: Lead) {
    setBusyId(lead.id)
    try {
      await createQuoteFromLead(lead.id)
      await reload()
    } finally { setBusyId(null) }
  }

  async function convert(lead: Lead) {
    setBusyId(lead.id)
    try {
      await convertLeadToClient(lead.id)
      await reload()
    } finally { setBusyId(null) }
  }

  async function move(lead: Lead, direction: -1 | 1) {
    const index = CRM_COLUMNS.findIndex((item) => item.status === lead.status)
    const target = CRM_COLUMNS[index + direction]
    if (!target) return
    setBusyId(lead.id)
    try {
      await changeLeadStatus(lead.id, target.status)
      await reload()
    } finally { setBusyId(null) }
  }

  if (loading) return <p className="text-sm text-muted-foreground">Carregando CRM...</p>

  return (
    <div className="overflow-x-auto pb-4">
      <div className="grid min-w-[1500px] grid-cols-6 gap-4">
        {CRM_COLUMNS.map((column) => (
          <section key={column.status} className="rounded-xl bg-muted/40 p-3">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="font-semibold">{column.label}</h2>
              <span className="rounded-full bg-background px-2 py-0.5 text-xs">{grouped[column.status]?.length ?? 0}</span>
            </div>
            <div className="space-y-3">
              {(grouped[column.status] ?? []).map((lead) => (
                <article key={lead.id} className="rounded-xl border bg-card p-3 shadow-sm">
                  <h3 className="font-medium">{lead.name}</h3>
                  <p className="mt-1 text-xs text-muted-foreground">{[lead.event_type, lead.event_date, lead.city].filter(Boolean).join(' · ') || 'Evento ainda não detalhado'}</p>
                  {lead.source && <p className="mt-1 text-xs text-muted-foreground">Origem: {lead.source}</p>}

                  <div className="mt-3 flex flex-wrap gap-2">
                    {['novo','em_atendimento'].includes(lead.status) && (
                      <button disabled={busyId === lead.id} onClick={() => createQuote(lead)} className="rounded-md border px-2 py-1 text-xs">Criar orçamento</button>
                    )}
                    {['orcamento','negociacao'].includes(lead.status) && (
                      <button disabled={busyId === lead.id} onClick={() => convert(lead)} className="rounded-md bg-slate-900 px-2 py-1 text-xs text-white">Converter em cliente</button>
                    )}
                    <button disabled={busyId === lead.id || lead.status === 'novo'} onClick={() => move(lead, -1)} className="rounded-md border px-2 py-1 text-xs">←</button>
                    <button disabled={busyId === lead.id || ['ganho','perdido'].includes(lead.status)} onClick={() => move(lead, 1)} className="rounded-md border px-2 py-1 text-xs">→</button>
                  </div>
                </article>
              ))}
            </div>
          </section>
        ))}
      </div>
    </div>
  )
}
