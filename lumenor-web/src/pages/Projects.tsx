import { useState, type FormEvent } from 'react'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getProjects, createProject } from '../lib/data'
import { PageHeader, Card, Spinner, ErrorState, Button, EmptyState } from '../components/ui'

export default function Projects() {
  const { session } = useAuth()
  const cid = session!.companyId
  const { data, loading, error, reload } = useAsync(() => getProjects(cid), [cid])

  const [name, setName] = useState('')
  const [subjectCode, setSubjectCode] = useState('')
  const [section, setSection] = useState('')
  const [busy, setBusy] = useState(false)
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null)

  async function add(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setMsg(null)
    const res = await createProject(cid, name, subjectCode, section)
    setBusy(false)
    setMsg({ ok: res.ok, text: res.message })
    if (res.ok) {
      setName('')
      setSubjectCode('')
      setSection('')
      reload()
    }
  }

  const input =
    'w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20'

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  return (
    <>
      <PageHeader title="Projects" subtitle="Subjects, sections and the work assigned to your team" />

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="p-5 lg:sticky lg:top-6 lg:self-start">
          <h2 className="mb-4 text-base font-bold text-slate-900">Create Project</h2>
          <form onSubmit={add} className="space-y-3">
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Project name"
              className={input}
            />
            <input
              value={subjectCode}
              onChange={(e) => setSubjectCode(e.target.value)}
              placeholder="Subject code"
              className={input}
            />
            <input
              value={section}
              onChange={(e) => setSection(e.target.value)}
              placeholder="Section"
              className={input}
            />
            {msg && (
              <p className={`text-sm ${msg.ok ? 'text-emerald-600' : 'text-rose-600'}`}>{msg.text}</p>
            )}
            <Button type="submit" disabled={busy}>
              {busy ? 'Creating…' : 'Create project'}
            </Button>
          </form>
        </Card>

        <div className="lg:col-span-2">
          {data.length === 0 ? (
            <EmptyState title="No projects yet" subtitle="Create your first project using the form." />
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {data.map((p) => (
                <Card key={p.subject_id} className="flex flex-col p-5">
                  <h3 className="text-base font-bold text-slate-900">{p.name}</h3>
                  <p className="mt-0.5 font-mono text-xs text-slate-500">{p.subject_code}</p>
                  {p.section && (
                    <p className="mt-1 text-sm text-slate-600">Section: {p.section}</p>
                  )}
                  <div className="mt-4 grid grid-cols-2 gap-2">
                    <div className="rounded-xl bg-slate-50 px-3 py-2">
                      <p className="text-lg font-extrabold text-brand">{p.total_classes ?? 0}</p>
                      <p className="text-xs text-slate-500">Meetings</p>
                    </div>
                    <div className="rounded-xl bg-slate-50 px-3 py-2">
                      <p className="text-lg font-extrabold text-brand">{p.total_employees ?? 0}</p>
                      <p className="text-xs text-slate-500">Employees</p>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      </div>
    </>
  )
}
