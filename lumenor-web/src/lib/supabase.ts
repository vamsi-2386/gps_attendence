import { createClient } from '@supabase/supabase-js'

// The anon/publishable key is safe to ship in a browser bundle (it only allows
// what your Supabase policies allow). Values come from Vite env vars, with the
// project defaults baked in so the app works out of the box.
const env = import.meta.env as Record<string, string | undefined>
const url = env.VITE_SUPABASE_URL ?? 'https://hpooyhqbooruuvhziwei.supabase.co'
const anonKey =
  env.VITE_SUPABASE_ANON_KEY ?? 'sb_publishable_4SyX2VTIPXR-T2DQhh4x0g_r1-K0OrT'

export const supabase = createClient(url, anonKey, {
  auth: { persistSession: false },
})
