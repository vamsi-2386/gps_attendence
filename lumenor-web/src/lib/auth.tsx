import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import bcrypt from 'bcryptjs'
import { supabase } from './supabase'
import type { Session } from './types'

interface AuthCtx {
  session: Session | null
  loading: boolean
  login: (username: string, password: string) => Promise<{ ok: boolean; message?: string }>
  logout: () => void
}

const Ctx = createContext<AuthCtx | null>(null)
const STORAGE_KEY = 'lumenor_session'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) setSession(JSON.parse(raw) as Session)
    } catch {
      /* ignore corrupt session */
    }
    setLoading(false)
  }, [])

  async function login(username: string, password: string) {
    const u = username.trim()
    if (!u || !password) return { ok: false, message: 'Enter username and password.' }

    // 1) Company login (companys table)
    const { data: companies } = await supabase
      .from('companys')
      .select('id, name, username, password')
      .ilike('username', u)
      .limit(1)
    if (companies && companies.length) {
      const c = companies[0] as { id: number; name: string; username: string; password: string }
      if (c.password && bcrypt.compareSync(password, c.password)) {
        return persist({ role: 'company', companyId: c.id, name: c.name, username: c.username })
      }
    }

    // 2) Manager / HR staff login (staff_accounts table)
    const { data: staff } = await supabase
      .from('staff_accounts')
      .select('id, company_id, name, username, password, role')
      .ilike('username', u)
      .limit(1)
    if (staff && staff.length) {
      const s = staff[0] as {
        company_id: number
        name: string
        username: string
        password: string
        role: 'manager' | 'hr'
      }
      if (s.password && bcrypt.compareSync(password, s.password)) {
        return persist({ role: s.role, companyId: s.company_id, name: s.name, username: s.username })
      }
    }

    return { ok: false, message: 'Invalid username or password.' }
  }

  function persist(s: Session) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(s))
    setSession(s)
    return { ok: true }
  }

  function logout() {
    localStorage.removeItem(STORAGE_KEY)
    setSession(null)
  }

  return <Ctx.Provider value={{ session, loading, login, logout }}>{children}</Ctx.Provider>
}

export function useAuth(): AuthCtx {
  const ctx = useContext(Ctx)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
