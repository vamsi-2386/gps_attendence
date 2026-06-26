import { useState, type FormEvent } from 'react'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getStaff, createStaff, deleteStaff } from '../lib/data'
import { PageHeader, Card, Spinner, ErrorState, Button, Badge } from '../components/ui'

export default function Staff() {
  const { session } = useAuth()
  const cid = session!.companyId
  const { data, loading, error, reload } = useAsync(() => getStaff(cid), [cid])

  const [name, setName] = useState('')
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [email, setEmail] = useState('')
  const [role, setRole] = useState('manager')
  const [busy, setBusy] = useState(false)
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null)

  // Only the company owner or an HR admin can manage staff accounts.
  const canManage = session!.role === 'company' || session!.role === 'hr'

  async function add(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setMsg(null)
    const res = await createStaff(cid, name, username, password, role, email)
    setBusy(false)
    setMsg({ ok: res.ok, text: res.message })
    if (res.ok) {
      setName('')
      setUsername('')
      setPassword('')
      setEmail('')
      reload()
    }
  }

  const input = 'w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20'

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  return (
    <>
      <PageHeader
        title="Managers & HR"
        subtitle="These accounts sign in here AND on the Lumenor HRMS mobile app"
      />
      <div className="grid gap-6 lg:grid-cols-2">
        {canManage && (
          <Card className="p-5">
            <h2 className="mb-4 text-base font-bold text-slate-900">Add a profile</h2>
            <form onSubmit={add} className="space-y-3">
              <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Full name" className={input} />
              <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email (optional)" className={input} />
              <input value={username} onChange={(e) => setUsername(e.target.value)} placeholder="Username" className={input} />
              <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Password" className={input} />
              <select value={role} onChange={(e) => setRole(e.target.value)} className={input}>
                <option value="manager">Manager</option>
                <option value="hr">HR Admin</option>
              </select>
              {msg && <p className={`text-sm ${msg.ok ? 'text-emerald-600' : 'text-rose-600'}`}>{msg.text}</p>}
              <Button type="submit" disabled={busy}>
                {busy ? 'Creating…' : 'Create account'}
              </Button>
            </form>
          </Card>
        )}

        <Card className="p-5">
          <h2 className="mb-4 text-base font-bold text-slate-900">Existing profiles</h2>
          {data.length === 0 ? (
            <p className="text-sm text-slate-500">No Manager/HR profiles yet.</p>
          ) : (
            <div className="space-y-2">
              {data.map((s) => (
                <div
                  key={s.id}
                  className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 p-3"
                >
                  <div className="min-w-0">
                    <p className="flex items-center gap-2 truncate text-sm font-semibold text-slate-800">
                      {s.name}
                      <Badge tone={s.role === 'hr' ? 'approved' : 'slate'}>
                        {s.role === 'hr' ? 'HR' : 'Manager'}
                      </Badge>
                    </p>
                    <p className="truncate text-xs text-slate-500">
                      @{s.username}
                      {s.email ? ` · ${s.email}` : ''}
                    </p>
                  </div>
                  {canManage && (
                    <Button
                      variant="ghost"
                      onClick={async () => {
                        await deleteStaff(s.id)
                        reload()
                      }}
                    >
                      Remove
                    </Button>
                  )}
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </>
  )
}
