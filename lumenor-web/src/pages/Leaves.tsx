import { useState } from 'react'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getLeaves, setLeaveStatus } from '../lib/data'
import { fmtDate } from '../lib/format'
import { PageHeader, Card, Spinner, ErrorState, EmptyState, Badge, Button } from '../components/ui'

export default function Leaves() {
  const { session } = useAuth()
  const cid = session!.companyId
  const { data, loading, error, reload } = useAsync(() => getLeaves(cid), [cid])
  const [busy, setBusy] = useState<number | null>(null)

  async function decide(id: number, status: 'Approved' | 'Rejected') {
    setBusy(id)
    try {
      await setLeaveStatus(id, status)
      reload()
    } finally {
      setBusy(null)
    }
  }

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  const pending = data.filter((l) => l.status === 'Pending')
  const decided = data.filter((l) => l.status !== 'Pending')

  return (
    <>
      <PageHeader title="Leave Approvals" subtitle={`${pending.length} pending`} />
      {data.length === 0 ? (
        <EmptyState title="No leave requests" subtitle="Requests submitted on the mobile app appear here." />
      ) : (
        <div className="space-y-6">
          <section className="space-y-3">
            {pending.length === 0 && (
              <p className="text-sm text-slate-500">No pending requests. 🎉</p>
            )}
            {pending.map((l) => (
              <Card key={l.id} className="p-4">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <p className="font-semibold text-slate-800">{l.employee_name}</p>
                    <p className="text-sm text-slate-600">
                      {fmtDate(l.start_date)} → {fmtDate(l.end_date)}
                    </p>
                    {l.reason && <p className="mt-1 text-sm text-slate-500">{l.reason}</p>}
                  </div>
                  <div className="flex gap-2">
                    <Button variant="success" disabled={busy === l.id} onClick={() => decide(l.id, 'Approved')}>
                      Approve
                    </Button>
                    <Button variant="danger" disabled={busy === l.id} onClick={() => decide(l.id, 'Rejected')}>
                      Reject
                    </Button>
                  </div>
                </div>
              </Card>
            ))}
          </section>

          {decided.length > 0 && (
            <section>
              <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-400">History</h2>
              <Card className="divide-y divide-slate-100">
                {decided.map((l) => (
                  <div key={l.id} className="flex items-center justify-between gap-3 p-4">
                    <div>
                      <p className="text-sm font-semibold text-slate-800">{l.employee_name}</p>
                      <p className="text-xs text-slate-500">
                        {fmtDate(l.start_date)} → {fmtDate(l.end_date)}
                      </p>
                    </div>
                    <Badge tone={l.status === 'Approved' ? 'approved' : 'rejected'}>{l.status}</Badge>
                  </div>
                ))}
              </Card>
            </section>
          )}
        </div>
      )}
    </>
  )
}
