import { useMemo } from 'react'
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getAttendance } from '../lib/data'
import { localDateKey, todayKey } from '../lib/format'
import { PageHeader, StatCard, Card, Spinner, ErrorState, EmptyState } from '../components/ui'

export default function Analytics() {
  const { session } = useAuth()
  const cid = session!.companyId

  const { data, loading, error } = useAsync(() => getAttendance(cid), [cid])

  const attendance = data ?? []

  const today = todayKey()

  const presentToday = useMemo(
    () =>
      new Set(
        attendance
          .filter(
            (a) =>
              (a.is_present === true || a.attendance_status === 'Present') &&
              localDateKey(a.check_in_time ?? a.timestamp) === today,
          )
          .map((a) => a.employee_id),
      ).size,
    [attendance, today],
  )

  const totalChecks = attendance.length

  const pendingReview = useMemo(
    () => attendance.filter((a) => a.attendance_status === 'Flagged').length,
    [attendance],
  )

  const series = useMemo(() => {
    const counts = new Map<string, number>()
    for (const a of attendance) {
      const key = localDateKey(a.check_in_time ?? a.timestamp)
      if (!key) continue
      counts.set(key, (counts.get(key) ?? 0) + 1)
    }
    return Array.from(counts.entries())
      .map(([date, count]) => ({ date, count }))
      .sort((x, y) => (x.date < y.date ? -1 : x.date > y.date ? 1 : 0))
  }, [attendance])

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  return (
    <>
      <PageHeader title="Analytics" subtitle="Attendance insights at a glance" />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard label="Present today" value={presentToday} tone="green" icon="✅" />
        <StatCard label="Total recorded checks" value={totalChecks} tone="brand" icon="📋" />
        <StatCard label="Pending HR review" value={pendingReview} tone="red" icon="⚖️" />
      </div>

      <h2 className="mb-3 mt-8 text-lg font-bold text-slate-900">Attendance Over Time</h2>
      <Card>
        {series.length === 0 ? (
          <EmptyState title="No attendance data" subtitle="Check-ins will appear here once recorded." />
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <LineChart data={series}>
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Line type="monotone" dataKey="count" stroke="#5b5bf6" />
            </LineChart>
          </ResponsiveContainer>
        )}
      </Card>
    </>
  )
}
