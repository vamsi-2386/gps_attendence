import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { fmtDateTime } from '../lib/format'
import { getAuditLogs } from '../lib/data'
import type { AuditLog } from '../lib/types'
import {
  Spinner,
  Card,
  PageHeader,
  EmptyState,
  ErrorState,
  Badge,
} from '../components/ui'

export default function Audit() {
  const { session } = useAuth()
  const cid = session!.companyId

  const { data, loading, error } = useAsync<AuditLog[]>(
    () => getAuditLogs(cid),
    [cid],
  )

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <Spinner />
      </div>
    )
  }

  if (error) return <ErrorState />

  const logs = data ?? []

  return (
    <div className="space-y-6">
      <PageHeader
        title="Audit Logs"
        subtitle="A chronological record of administrative actions across your company."
      />

      {logs.length === 0 ? (
        <EmptyState
          title="No audit logs yet"
          subtitle="Administrative actions will appear here as they happen."
        />
      ) : (
        <Card className="overflow-x-auto">
          <table className="min-w-[720px] w-full text-sm">
            <thead>
              <tr className="border-b border-slate-200 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                <th className="px-4 py-3">Timestamp</th>
                <th className="px-4 py-3">Action</th>
                <th className="px-4 py-3">Role</th>
                <th className="px-4 py-3">User ID</th>
                <th className="px-4 py-3">Details</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {logs.map((log, i) => {
                const details =
                  typeof log.details === 'string'
                    ? log.details
                    : JSON.stringify(log.details)
                return (
                  <tr key={i} className="text-slate-700 hover:bg-slate-50">
                    <td className="whitespace-nowrap px-4 py-3 text-slate-600">
                      {fmtDateTime(log.created_at)}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 font-medium text-slate-900">
                      {log.action_type}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3">
                      <Badge tone="slate">{log.user_role}</Badge>
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 text-slate-600">
                      {log.user_id}
                    </td>
                    <td className="px-4 py-3">
                      <code
                        className="block max-w-[28rem] truncate rounded bg-slate-100 px-2 py-1 font-mono text-xs text-slate-700"
                        title={details}
                      >
                        {details}
                      </code>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  )
}
