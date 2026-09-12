import { useEffect, useState } from 'react'
import type { ActiveCompanyContext } from '@/lib/company-context'
import { listInventoryConflicts } from '@/lib/inventory'

type Conflict = {
  event_id: string
  item_id: string
  item_name: string
  quantity: number
  available_excluding_event: number
  reserved_from: string
  reserved_until: string
}

export function InventoryConflictAlerts({ company }: { company: ActiveCompanyContext }) {
  const [items, setItems] = useState<Conflict[]>([])

  useEffect(() => {
    let active = true
    listInventoryConflicts(company.companyId).then((data) => active && setItems(data as Conflict[]))
    return () => { active = false }
  }, [company.companyId])

  if (!items.length) return null

  return (
    <section className="rounded-xl border border-red-200 bg-red-50 p-4">
      <h2 className="font-semibold text-red-900">Conflitos de estoque</h2>
      <p className="mt-1 text-sm text-red-800">Existem reservas que precisam de revisão antes da operação.</p>
      <div className="mt-3 grid gap-2 lg:grid-cols-2">
        {items.map((item) => (
          <article key={`${item.event_id}-${item.item_id}`} className="rounded-lg bg-white p-3 text-sm shadow-sm">
            <strong>{item.item_name}</strong>
            <p className="text-muted-foreground">Reservado: {item.quantity} · disponível no período: {item.available_excluding_event}</p>
          </article>
        ))}
      </div>
    </section>
  )
}
