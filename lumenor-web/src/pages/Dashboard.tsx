import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getCompany, getEmployees, getAttendance, getLeaves } from '../lib/data'
import { localDateKey, todayKey } from '../lib/format'
import { PageHeader, StatCard, Card, Spinner, ErrorState, Badge } from '../components/ui'

export default function Dashboard() {
  const { session } = useAuth()
  const cid = session!.companyId

  const { data, loading, error } = useAsync(
    async () => {
      const [company, employees, attendance, pending] = await Promise.all([
        getCompany(cid),
        getEmployees(cid),
        getAttendance(cid),
        getLeaves(cid, 'Pending'),
      ])
      return { company, employees, attendance, pending }
    },
    [cid],
  )

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  const { company, employees, attendance, pending } = data
  const today = todayKey()

  const presentIds = new Set(
    attendance
      .filter(
        (a) =>
          (a.is_present === true || a.attendance_status === 'Present') &&
          localDateKey(a.check_in_time ?? a.timestamp) === today,
      )
      .map((a) => a.employee_id),
  )
  const onLeaveIds = new Set(pending.map((l) => l.employee_id))
  const flaggedCount = attendance.filter((a) => a.attendance_status === 'Flagged').length

  const rows = employees.map((e) => {
    const status =
      onLeaveIds.has(e.employee_id) && !presentIds.has(e.employee_id)
        ? 'Leave'
        : presentIds.has(e.employee_id)
          ? 'Present'
          : 'Absent'
    return { e, status }
  })
  const present = rows.filter((r) => r.status === 'Present').length
  const absent = rows.filter((r) => r.status === 'Absent').length

  return (
    <>
      <PageHeader title={`Welcome, ${session!.name}`} subtitle="Today at a glance" />

      {company && (
        <Card className="mb-6 border border-brand/20 bg-brand-light">
          <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-brand">
                Company Invite Code
              </p>
              <p className="mt-1 text-2xl font-bold tracking-wider text-slate-900">
                {company.company_invite_code ?? '—'}
              </p>
            </div>
            <p className="text-xs text-slate-500">Share with employees so they can join</p>
          </div>
        </Card>
      )}

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard label="Total employees" value={employees.length} tone="brand" icon="👥" />
        <StatCard label="Present today" value={present} tone="green" icon="✅" />
        <StatCard label="Pending leave" value={pending.length} tone="amber" icon="🏖️" />
        <StatCard label="Pending HR review" value={flaggedCount} tone="red" icon="⚖️" />
      </div>

      <h2 className="mb-3 mt-8 text-lg font-bold text-slate-900">Team ({absent} absent)</h2>
      <Card className="divide-y divide-slate-100">
        {rows.length === 0 && <p className="p-6 text-sm text-slate-500">No employees yet.</p>}
        {rows.map(({ e, status }) => (
          <div key={e.employee_id} className="flex items-center gap-3 p-4">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-brand-light text-sm font-bold text-brand">
              {e.name?.trim()?.charAt(0)?.toUpperCase() ?? '?'}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold text-slate-800">{e.name}</p>
              <p className="truncate text-xs text-slate-500">
                {e.designation || e.role || 'Employee'} · {e.employee_code}
              </p>
            </div>
            <Badge tone={status === 'Present' ? 'present' : status === 'Leave' ? 'pending' : 'rejected'}>
              {status}
            </Badge>
          </div>
        ))}
      </Card>
    </>
  )
}
