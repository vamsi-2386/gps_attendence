import { useMemo, useState, type FormEvent } from 'react'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getEmployees, getOffices, registerEmployee, updateDesignation } from '../lib/data'
import type { Employee, Office } from '../lib/types'
import { PageHeader, Card, Spinner, ErrorState, EmptyState, Button } from '../components/ui'

const input =
  'w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20'

export default function Employees() {
  const { session } = useAuth()
  const cid = session!.companyId
  const { data, loading, error, reload } = useAsync(
    () => Promise.all([getEmployees(cid), getOffices(cid)]),
    [cid],
  )

  // Register form state
  const [code, setCode] = useState('')
  const [name, setName] = useState('')
  const [designation, setDesignation] = useState('')
  const [dailyRate, setDailyRate] = useState('')
  const [mobile, setMobile] = useState('')
  const [email, setEmail] = useState('')
  const [officeId, setOfficeId] = useState('')
  const [busy, setBusy] = useState(false)
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null)

  // Per-row edited designations: employee_id -> value
  const [edits, setEdits] = useState<Record<number, string>>({})
  const [savingDesignations, setSavingDesignations] = useState(false)

  const employees: Employee[] = data?.[0] ?? []
  const offices: Office[] = data?.[1] ?? []

  const dirtyEdits = useMemo(() => {
    const out: { id: number; designation: string }[] = []
    for (const emp of employees) {
      const edited = edits[emp.employee_id]
      if (edited === undefined) continue
      const original = emp.designation ?? ''
      if (edited !== original) out.push({ id: emp.employee_id, designation: edited })
    }
    return out
  }, [employees, edits])

  async function register(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setMsg(null)
    const res = await registerEmployee({
      companyId: cid,
      employeeCode: code.trim(),
      name: name.trim(),
      designation: designation.trim(),
      dailyRate: dailyRate ? Number(dailyRate) : 0,
      officeId: officeId ? Number(officeId) : undefined,
      mobile: mobile.trim() || undefined,
      email: email.trim() || undefined,
    })
    setBusy(false)
    setMsg({ ok: res.ok, text: res.message })
    if (res.ok) {
      setCode('')
      setName('')
      setDesignation('')
      setDailyRate('')
      setMobile('')
      setEmail('')
      setOfficeId('')
      setEdits({})
      reload()
    }
  }

  async function saveDesignations() {
    if (dirtyEdits.length === 0) return
    setSavingDesignations(true)
    for (const d of dirtyEdits) {
      await updateDesignation(d.id, d.designation)
    }
    setSavingDesignations(false)
    setEdits({})
    reload()
  }

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  return (
    <>
      <PageHeader title="Employees" subtitle={`${employees.length} on the roster`} />

      <div className="space-y-6">
        <Card className="p-5">
          <h2 className="mb-4 text-base font-bold text-slate-900">Register employee</h2>
          <form onSubmit={register} className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              <div>
                <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Employee code
                </label>
                <input
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  placeholder="EMP001"
                  required
                  className={input}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Full name
                </label>
                <input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Jane Doe"
                  required
                  className={input}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Designation
                </label>
                <input
                  value={designation}
                  onChange={(e) => setDesignation(e.target.value)}
                  placeholder="Field Officer"
                  className={input}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Daily rate
                </label>
                <input
                  type="number"
                  min="0"
                  step="any"
                  value={dailyRate}
                  onChange={(e) => setDailyRate(e.target.value)}
                  placeholder="0"
                  className={input}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Mobile
                </label>
                <input
                  value={mobile}
                  onChange={(e) => setMobile(e.target.value)}
                  placeholder="Optional"
                  className={input}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Email
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Optional"
                  className={input}
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Office
                </label>
                <select value={officeId} onChange={(e) => setOfficeId(e.target.value)} className={input}>
                  <option value="">No office assigned</option>
                  {offices.map((o) => (
                    <option key={o.id} value={o.id}>
                      {o.office_name}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            {msg && (
              <p className={`text-sm ${msg.ok ? 'text-emerald-600' : 'text-rose-600'}`}>{msg.text}</p>
            )}
            <Button type="submit" disabled={busy}>
              {busy ? 'Registering…' : 'Register employee'}
            </Button>
          </form>
        </Card>

        <div className="flex items-center justify-between gap-3">
          <h2 className="text-base font-bold text-slate-900">Directory</h2>
          <Button
            variant="outline"
            onClick={saveDesignations}
            disabled={savingDesignations || dirtyEdits.length === 0}
          >
            {savingDesignations
              ? 'Saving…'
              : dirtyEdits.length > 0
                ? `Save designations (${dirtyEdits.length})`
                : 'Save designations'}
          </Button>
        </div>

        {employees.length === 0 ? (
          <EmptyState
            title="No employees yet"
            subtitle="Register your first employee using the form above."
          />
        ) : (
          <Card className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3">Code</th>
                  <th className="px-4 py-3">Name</th>
                  <th className="px-4 py-3">Designation</th>
                  <th className="px-4 py-3">Mobile</th>
                  <th className="px-4 py-3">Email</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {employees.map((emp) => {
                  const value =
                    edits[emp.employee_id] !== undefined
                      ? edits[emp.employee_id]
                      : emp.designation ?? ''
                  return (
                    <tr key={emp.employee_id} className="hover:bg-slate-50">
                      <td className="px-4 py-3 font-mono text-xs text-slate-600">{emp.employee_code}</td>
                      <td className="px-4 py-3 font-semibold text-slate-800">{emp.name}</td>
                      <td className="px-4 py-3">
                        <input
                          value={value}
                          onChange={(e) =>
                            setEdits((prev) => ({ ...prev, [emp.employee_id]: e.target.value }))
                          }
                          placeholder="—"
                          className={input}
                        />
                      </td>
                      <td className="px-4 py-3 text-slate-600">{emp.mobile || '—'}</td>
                      <td className="px-4 py-3 text-slate-600">{emp.email || '—'}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </Card>
        )}
      </div>
    </>
  )
}
