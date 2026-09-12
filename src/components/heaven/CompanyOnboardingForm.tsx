import { useState, type FormEvent } from 'react'
import { supabase } from '@/integrations/supabase/client'

type CompanyOnboardingFormProps = {
  onCreated?: (companyId: string) => void
}

export function CompanyOnboardingForm({ onCreated }: CompanyOnboardingFormProps) {
  const [name, setName] = useState('')
  const [responsibleName, setResponsibleName] = useState('')
  const [whatsapp, setWhatsapp] = useState('')
  const [city, setCity] = useState('')
  const [state, setState] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (!name.trim()) {
      setError('Informe o nome da empresa.')
      return
    }

    setSaving(true)
    const { data, error: rpcError } = await supabase.rpc('create_company_with_owner', {
      company_name: name.trim(),
      responsible_name: responsibleName.trim() || null,
      company_email: null,
      company_whatsapp: whatsapp.trim() || null,
      company_city: city.trim() || null,
      company_state: state.trim().toUpperCase() || null,
    })
    setSaving(false)

    if (rpcError) {
      setError('Não foi possível criar sua empresa. Tente novamente.')
      return
    }

    if (typeof data === 'string') onCreated?.(data)
  }

  return (
    <div className="mx-auto w-full max-w-2xl rounded-2xl border bg-white p-6 shadow-sm">
      <div className="mb-6">
        <p className="text-sm font-medium text-amber-700">Primeiro acesso</p>
        <h1 className="mt-1 text-2xl font-semibold text-slate-900">Vamos configurar sua empresa</h1>
        <p className="mt-2 text-sm text-slate-600">
          Essas informações pertencem somente à sua empresa e poderão ser alteradas depois em Configurações.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="grid gap-4 sm:grid-cols-2">
        <label className="sm:col-span-2">
          <span className="mb-1 block text-sm font-medium">Nome da empresa *</span>
          <input className="w-full rounded-lg border px-3 py-2" value={name} onChange={(e) => setName(e.target.value)} />
        </label>

        <label className="sm:col-span-2">
          <span className="mb-1 block text-sm font-medium">Responsável</span>
          <input className="w-full rounded-lg border px-3 py-2" value={responsibleName} onChange={(e) => setResponsibleName(e.target.value)} />
        </label>

        <label className="sm:col-span-2">
          <span className="mb-1 block text-sm font-medium">WhatsApp</span>
          <input className="w-full rounded-lg border px-3 py-2" value={whatsapp} onChange={(e) => setWhatsapp(e.target.value)} />
        </label>

        <label>
          <span className="mb-1 block text-sm font-medium">Cidade</span>
          <input className="w-full rounded-lg border px-3 py-2" value={city} onChange={(e) => setCity(e.target.value)} />
        </label>

        <label>
          <span className="mb-1 block text-sm font-medium">UF</span>
          <input className="w-full rounded-lg border px-3 py-2 uppercase" maxLength={2} value={state} onChange={(e) => setState(e.target.value)} />
        </label>

        {error && <p className="sm:col-span-2 text-sm text-red-600">{error}</p>}

        <div className="sm:col-span-2 flex justify-end">
          <button type="submit" disabled={saving} className="rounded-lg bg-slate-900 px-5 py-2.5 text-sm font-medium text-white disabled:opacity-60">
            {saving ? 'Criando empresa...' : 'Criar minha empresa'}
          </button>
        </div>
      </form>
    </div>
  )
}
