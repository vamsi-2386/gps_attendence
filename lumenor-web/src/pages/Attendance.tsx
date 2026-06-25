import { useMemo, useState } from 'react'
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts'
import { jsPDF } from 'jspdf'
import autoTable from 'jspdf-autotable'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getAttendance, getProjects, reviewFlaggedAttendance } from '../lib/data'
import { fmtDateTime } from '../lib/format'
import {
  PageHeader,
  StatCard,
  Card,
  Spinner,
  ErrorState,
  EmptyState,
  Badge,
  Button,
} from '../components/ui'
import type { AttendanceLog } from '../lib/types'

const PIE_COLORS = ['#10b981', '#f43f5e']

type DetailRow = {
  log: AttendanceLog
  employee: string
  checkIn: string
  checkOut: string
  worked: string
  geofence: string
  status: string
}

function statusTone(status: string): 'present' | 'flagged' | 'rejected' | 'slate' {
  if (status === 'Present') return 'present'
  if (status === 'Flagged') return 'flagged'
  if (status === 'Rejected') return 'rejected'
  return 'slate'
}

export default function Attendance() {
  const { session } = useAuth()
  const cid = session!.companyId

  const { data, loading, error, reload } = useAsync(async () => {
    const [attendance, projects] = await Promise.all([getAttendance(cid), getProjects(cid)])
    return { attendance, projects }
  }, [cid])

  const [busy, setBusy] = useState<number | null>(null)

  async function decide(id: number, approved: boolean) {
    setBusy(id)
    try {
      await reviewFlaggedAttendance(id, approved)
      reload()
    } finally {
      setBusy(null)
    }
  }

  const projectName = useMemo(() => {
    const map = new Map<number, string>()
    data?.projects.forEach((p) => map.set(p.subject_id, p.name))
    return map
  }, [data])

  const detailRows = useMemo<DetailRow[]>(() => {
    if (!data) return []
    return data.attendance.map((log) => {
      const checkOut = log.check_out_time ?? log.checkout_time
      return {
        log,
        employee: log.employee_name || `#${log.employee_id}`,
        checkIn: fmtDateTime(log.check_in_time ?? log.timestamp),
        checkOut: checkOut ? fmtDateTime(checkOut) : 'Still active',
        worked: log.worked_hours != null ? `${log.worked_hours.toFixed(2)} h` : '—',
        geofence: log.geofence_status || '—',
        status: log.attendance_status || '—',
      }
    })
  }, [data])

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  const { attendance } = data
  const total = attendance.length
  const present = attendance.filter((a) => a.is_present === true).length
  const absent = total - present

  const byProject = (() => {
    const counts = new Map<string, number>()
    for (const a of attendance) {
      if (a.is_present !== true) continue
      const key = a.subject_id != null ? projectName.get(a.subject_id) ?? '—' : '—'
      counts.set(key, (counts.get(key) ?? 0) + 1)
    }
    return Array.from(counts.entries()).map(([name, count]) => ({ name, present: count }))
  })()

  const pieData = [
    { name: 'Present', value: present },
    { name: 'Absent', value: absent },
  ]

  const flagged = attendance.filter((a) => a.attendance_status === 'Flagged')

  const csvHeader = ['Employee', 'Check-in', 'Check-out', 'Worked', 'Geofence', 'Status']

  function downloadCSV() {
    const escape = (v: string) => `"${v.replace(/"/g, '""')}"`
    const lines = [csvHeader.map(escape).join(',')]
    for (const r of detailRows) {
      lines.push(
        [r.employee, r.checkIn, r.checkOut, r.worked, r.geofence, r.status].map(escape).join(','),
      )
    }
    const blob = new Blob([lines.join('\r\n')], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'attendance.csv'
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  function downloadPDF() {
    const doc = new jsPDF()
    doc.setFontSize(14)
    doc.text('Attendance Records', 14, 16)
    autoTable(doc, {
      startY: 22,
      head: [csvHeader],
      body: detailRows.map((r) => [
        r.employee,
        r.checkIn,
        r.checkOut,
        r.worked,
        r.geofence,
        r.status,
      ]),
      styles: { fontSize: 8 },
      headStyles: { fillColor: [91, 91, 246] },
    })
    doc.save('attendance.pdf')
  }

  return (
    <>
      <PageHeader
        title="Records"
        subtitle="Attendance history, analytics and exports"
        action={
          <div className="flex gap-2">
            <Button variant="outline" onClick={downloadCSV}>
              Download CSV
            </Button>
            <Button variant="primary" onClick={downloadPDF}>
              Download PDF
            </Button>
          </div>
        }
      />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard label="Total logs" value={total} tone="brand" icon="🗂️" />
        <StatCard label="Present" value={present} tone="green" icon="✅" />
        <StatCard label="Absent" value={absent} tone="red" icon="🚫" />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card className="p-4">
          <h2 className="mb-3 text-sm font-bold text-slate-900">Attendance by Project</h2>
          {byProject.length === 0 ? (
            <EmptyState title="No present logs" subtitle="No attendance has been recorded yet." />
          ) : (
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={byProject}>
                <XAxis dataKey="name" />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Bar dataKey="present" fill="#5b5bf6" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </Card>

        <Card className="p-4">
          <h2 className="mb-3 text-sm font-bold text-slate-900">Present vs Absent</h2>
          {total === 0 ? (
            <EmptyState title="No records" subtitle="No attendance has been recorded yet." />
          ) : (
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie
                  data={pieData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={90}
                  label
                >
                  {pieData.map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          )}
        </Card>
      </div>

      <h2 className="mb-3 mt-8 text-lg font-bold text-slate-900">Detailed Records</h2>
      {detailRows.length === 0 ? (
        <EmptyState title="No records" subtitle="No attendance logs found for this company." />
      ) : (
        <Card className="overflow-x-auto">
          <table className="w-full min-w-[760px] text-left text-sm">
            <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-3">Employee</th>
                <th className="px-4 py-3">Check-in</th>
                <th className="px-4 py-3">Check-out</th>
                <th className="px-4 py-3">Worked</th>
                <th className="px-4 py-3">Geofence</th>
                <th className="px-4 py-3">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {detailRows.map((r) => (
                <tr key={r.log.id} className="hover:bg-slate-50">
                  <td className="px-4 py-3 font-semibold text-slate-800">{r.employee}</td>
                  <td className="px-4 py-3 text-slate-600">{r.checkIn}</td>
                  <td className="px-4 py-3 text-slate-600">{r.checkOut}</td>
                  <td className="px-4 py-3 text-slate-600">{r.worked}</td>
                  <td className="px-4 py-3 text-slate-600">{r.geofence}</td>
                  <td className="px-4 py-3">
                    <Badge tone={statusTone(r.status)}>{r.status}</Badge>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      <h2 className="mb-3 mt-8 text-lg font-bold text-slate-900">
        Flagged Check-ins ({flagged.length})
      </h2>
      {flagged.length === 0 ? (
        <EmptyState
          title="No flagged check-ins"
          subtitle="All check-ins are within geofence or already reviewed."
        />
      ) : (
        <div className="space-y-3">
          {flagged.map((a) => (
            <Card key={a.id} className="p-4">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="font-semibold text-slate-800">
                    {a.employee_name || `#${a.employee_id}`}
                  </p>
                  <p className="text-sm text-slate-600">
                    {fmtDateTime(a.check_in_time ?? a.timestamp)}
                  </p>
                  <p className="mt-1 text-xs text-slate-500">
                    Geofence: {a.geofence_status || 'Outside'}
                    {a.latitude != null && a.longitude != null
                      ? ` · ${a.latitude.toFixed(5)}, ${a.longitude.toFixed(5)}`
                      : ''}
                  </p>
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="success"
                    disabled={busy === a.id}
                    onClick={() => decide(a.id, true)}
                  >
                    Approve
                  </Button>
                  <Button
                    variant="danger"
                    disabled={busy === a.id}
                    onClick={() => decide(a.id, false)}
                  >
                    Reject
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </>
  )
}
