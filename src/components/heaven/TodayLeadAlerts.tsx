import { useEffect, useState } from 'react'
import type { ActiveCompanyContext } from '@/lib/company-context'
import { buildWhatsAppUrl, listActionableLeads, startLeadAttendance, type Lead } from '@/lib/leads'

export function TodayLeadAlerts({ company }: { company: ActiveCompanyContext }) {
  const [leads, setLeads] = useState<Lead[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true
    listActionableLeads(company.companyId)
      .then((data) => active && setLeads(data.filter((lead) => lead.status === 'novo')))
      .finally(() => active && setLoading(false))
    return () => { active = false }
  }, [company.companyId])

  if (loading) return <p className="text-sm text-muted-foreground">Carregando novos leads...</p>
  if (!leads.length) return null

  async function handleWhatsApp(lead: Lead) {
    const url = buildWhatsAppUrl(lead.phone, lead.name)
    if (!url) return
    await startLeadAttendance(lead.id)
    setLeads((current) => current.filter((item) => item.id !== lead.id))
    window.open(url, '_blank', 'noopener,noreferrer')
  }

  return (
    <section className="space-y-3">
      <div>
        <h2 className="text-lg font-semibold">Novos leads</h2>
        <p className="text-sm text-muted-foreground">Contatos novos que ainda não receberam o primeiro atendimento.</p>
      </div>

      <div className="grid gap-3 xl:grid-cols-2">
        {leads.map((lead) => (
          <article key={lead.id} className="rounded-xl border bg-card p-4 shadow-sm">
            <div className="flex items-start justify-between gap-4">
              <div>
                <span className="rounded-full bg-amber-100 px-2 py-1 text-xs font-medium text-amber-800">Novo lead</span>
                <h3 className="mt-2 font-semibold">{lead.name}</h3>
                <p className="text-sm text-muted-foreground">
                  {[lead.event_type, lead.city].filter(Boolean).join(' · ') || 'Sem detalhes do evento'}
                </p>
                {lead.source && <p className="mt-1 text-xs text-muted-foreground">Origem: {lead.source}</p>}
              </div>
              <button
                type="button"
                disabled={!lead.phone}
                onClick={() => handleWhatsApp(lead)}
                className="rounded-lg bg-emerald-700 px-3 py-2 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-50"
              >
                Chamar no WhatsApp
              </button>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}
