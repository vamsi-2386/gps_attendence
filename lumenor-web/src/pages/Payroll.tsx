import { useMemo, useState, type FormEvent } from 'react'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getEmployees, getAttendance, updateDailyRate, computePayroll } from '../lib/data'
import {
  PageHeader,
  Card,
  Spinner,
  ErrorState,
  EmptyState,
  StatCard,
  Button,
} from '../components/ui'
import type { Employee, AttendanceLog } from '../lib/types'

const inr = (n: number) =>
  '₹' + Math.round(n).toLocaleString('en-IN')

export default function Payroll() {
  const { session } = useAuth()
  const cid = session!.companyId

  const { data, loading, error, reload } = useAsync(
    () =>
      Promise.all([getEmployees(cid), getAttendance(cid)]) as Promise<
        [Employee[], AttendanceLog[]]
      >,
    [cid],
  )

  const employees = data?.[0] ?? []
  const attendance = data?.[1] ?? []

  const rows = useMemo(
    () => computePayroll(employees, attendance),
    [employees, attendance],
  )

  const totalPay = useMemo(
    () => rows.reduce((sum, r) => sum + (r.estimated_pay || 0), 0),
    [rows],
  )
  const totalPresentDays = useMemo(
    () => rows.reduce((sum, r) => sum + (r.present_days || 0), 0),
    [rows],
  )

  // --- Update daily rate form ---
  const [empId, setEmpId] = useState('')
  const [rate, setRate] = useState('')
  const [busy, setBusy] = useState(false)
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null)

  const input =
    'w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20'

  async function submitRate(e: FormEvent) {
    e.preventDefault()
    setMsg(null)
    const id = Number(empId)
    const r = Number(rate)
    if (!id) {
      setMsg({ ok: false, text: 'Select an employee.' })
      return
    }
    if (!Number.isFinite(r) || r < 0) {
      setMsg({ ok: false, text: 'Enter a valid daily rate.' })
      return
    }
    setBusy(true)
    try {
      await updateDailyRate(id, r)
      const emp = employees.find((x) => x.employee_id === id)
      setMsg({
        ok: true,
        text: `Daily rate for ${emp?.name ?? 'employee'} updated to ${inr(r)}.`,
      })
      setEmpId('')
      setRate('')
      reload()
    } catch {
      setMsg({ ok: false, text: 'Could not update the daily rate. Try again.' })
    } finally {
      setBusy(false)
    }
  }

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  return (
    <>
      <PageHeader
        title="Payroll"
        subtitle="Estimated pay from present days × daily rate"
      />

      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <StatCard label="Total estimated pay" value={inr(totalPay)} tone="green" />
        <StatCard label="Employees" value={rows.length} tone="brand" />
        <StatCard label="Total present days" value={totalPresentDays} tone="blue" />
      </div>

      <div className="grid gap-6 lg:grid-cols-[2fr_1fr]">
        {rows.length === 0 ? (
          <EmptyState
            title="No payroll data yet"
            subtitle="Register employees and record attendance to see estimated pay."
          />
        ) : (
          <Card className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3">Code</th>
                  <th className="px-4 py-3">Name</th>
                  <th className="px-4 py-3">Designation</th>
                  <th className="px-4 py-3 text-right">Daily Rate (₹)</th>
                  <th className="px-4 py-3 text-right">Present Days</th>
                  <th className="px-4 py-3 text-right">Estimated Pay (₹)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {rows.map((r) => (
                  <tr key={r.employee_id} className="hover:bg-slate-50">
                    <td className="px-4 py-3 font-mono text-xs text-slate-600">
                      {r.employee_code}
                    </td>
                    <td className="px-4 py-3 font-semibold text-slate-800">
                      {r.name}
                    </td>
                    <td className="px-4 py-3 text-slate-600">
                      {r.designation || 'Employee'}
                    </td>
                    <td className="px-4 py-3 text-right text-slate-600">
                      {inr(r.daily_rate || 0)}
                    </td>
                    <td className="px-4 py-3 text-right text-slate-600">
                      {r.present_days}
                    </td>
                    <td className="px-4 py-3 text-right font-semibold text-emerald-600">
                      {inr(r.estimated_pay || 0)}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="border-t border-slate-200 bg-slate-50 text-sm font-bold text-slate-800">
                <tr>
                  <td className="px-4 py-3" colSpan={5}>
                    Total
                  </td>
                  <td className="px-4 py-3 text-right text-emerald-700">
                    {inr(totalPay)}
                  </td>
                </tr>
              </tfoot>
            </table>
          </Card>
        )}

        <Card className="p-5">
          <h2 className="mb-4 text-base font-bold text-slate-900">
            Update daily rate
          </h2>
          {employees.length === 0 ? (
            <p className="text-sm text-slate-500">
              No employees available to update.
            </p>
          ) : (
            <form onSubmit={submitRate} className="space-y-3">
              <select
                value={empId}
                onChange={(e) => setEmpId(e.target.value)}
                className={input}
              >
                <option value="">Select employee…</option>
                {employees.map((e) => (
                  <option key={e.employee_id} value={e.employee_id}>
                    {e.name} ({e.employee_code})
                  </option>
                ))}
              </select>
              <input
                type="number"
                min="0"
                step="1"
                value={rate}
                onChange={(e) => setRate(e.target.value)}
                placeholder="New daily rate (₹)"
                className={input}
              />
              {msg && (
                <p
                  className={`text-sm ${
                    msg.ok ? 'text-emerald-600' : 'text-rose-600'
                  }`}
                >
                  {msg.text}
                </p>
              )}
              <Button type="submit" disabled={busy}>
                {busy ? 'Saving…' : 'Update rate'}
              </Button>
            </form>
          )}
        </Card>
      </div>
    </>
  )
}
