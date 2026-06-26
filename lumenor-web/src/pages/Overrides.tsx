import { useState } from 'react'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { fmtDateTime } from '../lib/format'
import { getOverrides, reviewOverride } from '../lib/data'
import type { Override, VerificationEvent } from '../lib/types'
import {
  Spinner,
  Card,
  PageHeader,
  Badge,
  Button,
  EmptyState,
  ErrorState,
} from '../components/ui'

export default function Overrides() {
  const { session } = useAuth()
  const cid = session!.companyId

  const { data, loading, error, reload } = useAsync<Override[]>(
    () => getOverrides(cid),
    [cid],
  )

  const [notes, setNotes] = useState<Record<number, string>>({})
  const [busy, setBusy] = useState<Record<number, boolean>>({})

  async function handleReview(o: Override, approved: boolean) {
    setBusy((b) => ({ ...b, [o.id]: true }))
    try {
      await reviewOverride(o.id, approved, notes[o.id] ?? '', cid)
      setNotes((n) => {
        const next = { ...n }
        delete next[o.id]
        return next
      })
      reload()
    } finally {
      setBusy((b) => ({ ...b, [o.id]: false }))
    }
  }

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  return (
    <>
      <PageHeader
        title="HR Overrides"
        subtitle="Verification failures awaiting review"
      />

      {data.length === 0 ? (
        <EmptyState title="No pending overrides" />
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {data.map((o) => {
            const event: VerificationEvent | undefined = Array.isArray(
              o.verification_events,
            )
              ? o.verification_events[0]
              : o.verification_events
            const isBusy = !!busy[o.id]
            return (
              <Card key={o.id} className="flex flex-col gap-4 p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-medium uppercase tracking-wide text-slate-400">
                      Employee ID
                    </p>
                    <p className="text-lg font-semibold text-slate-800">
                      {o.employee_id}
                    </p>
                  </div>
                  <Badge tone="pending">{o.status || 'Pending'}</Badge>
                </div>

                <dl className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-2">
                  <div>
                    <dt className="text-xs font-medium uppercase tracking-wide text-slate-400">
                      Failed step
                    </dt>
                    <dd className="mt-0.5 font-medium text-slate-700">
                      {event?.step_name || 'Unknown'}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-xs font-medium uppercase tracking-wide text-slate-400">
                      Time
                    </dt>
                    <dd className="mt-0.5 font-medium text-slate-700">
                      {fmtDateTime(event?.created_at)}
                    </dd>
                  </div>
                  <div className="sm:col-span-2">
                    <dt className="text-xs font-medium uppercase tracking-wide text-slate-400">
                      Reason
                    </dt>
                    <dd className="mt-0.5 font-medium text-slate-700">
                      {event?.failure_reason || 'N/A'}
                    </dd>
                  </div>
                </dl>

                <div>
                  <label
                    htmlFor={`notes-${o.id}`}
                    className="mb-1 block text-xs font-medium uppercase tracking-wide text-slate-400"
                  >
                    HR notes
                  </label>
                  <input
                    id={`notes-${o.id}`}
                    type="text"
                    value={notes[o.id] ?? ''}
                    onChange={(e) =>
                      setNotes((n) => ({ ...n, [o.id]: e.target.value }))
                    }
                    placeholder="Add a note for this decision"
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-700 placeholder:text-slate-400 focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-100"
                  />
                </div>

                <div className="mt-auto flex gap-2">
                  <Button
                    variant="success"
                    disabled={isBusy}
                    onClick={() => handleReview(o, true)}
                  >
                    Approve
                  </Button>
                  <Button
                    variant="danger"
                    disabled={isBusy}
                    onClick={() => handleReview(o, false)}
                  >
                    Reject
                  </Button>
                </div>
              </Card>
            )
          })}
        </div>
      )}
    </>
  )
}
