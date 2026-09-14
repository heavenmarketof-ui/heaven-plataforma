import { createClient } from '@supabase/supabase-js'

const supabaseUrl = String(import.meta.env.VITE_SUPABASE_URL ?? '').trim()
const supabaseKey = String(import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? '').trim()

export const supabaseConfigured = Boolean(supabaseUrl && supabaseKey)
export const supabaseProjectHost = supabaseConfigured
  ? (() => {
      try { return new URL(supabaseUrl).host }
      catch { return 'URL inválida' }
    })()
  : 'não configurado'

if (!supabaseConfigured) {
  console.error('[Heaven] Configuração do Supabase ausente no build. Verifique VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY.')
}

export const supabase = createClient(
  supabaseUrl || 'https://invalid.supabase.co',
  supabaseKey || 'missing-publishable-key',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  },
)
