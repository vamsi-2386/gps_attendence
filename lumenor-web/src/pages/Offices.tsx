import { useState, type FormEvent } from 'react'
import { useAuth } from '../lib/auth'
import { useAsync } from '../lib/useAsync'
import { getOffices, createOffice, deleteOffice } from '../lib/data'
import { PageHeader, Card, Spinner, ErrorState, EmptyState, Button } from '../components/ui'
import { OfficeMap } from '../components/OfficeMap'

export default function Offices() {
  const { session } = useAuth()
  const cid = session!.companyId
  const { data, loading, error, reload } = useAsync(() => getOffices(cid), [cid])

  const [name, setName] = useState('')
  const [lat, setLat] = useState('')
  const [lng, setLng] = useState('')
  const [radius, setRadius] = useState('100')
  const [busy, setBusy] = useState(false)
  const [locating, setLocating] = useState(false)
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null)

  const input =
    'w-full rounded-xl border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20'

  const latNum = parseFloat(lat)
  const lngNum = parseFloat(lng)
  const hasCoords = Number.isFinite(latNum) && Number.isFinite(lngNum)

  function useMyLocation() {
    if (!navigator.geolocation) {
      setMsg({ ok: false, text: 'Geolocation is not supported on this device.' })
      return
    }
    setLocating(true)
    setMsg(null)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLat(String(pos.coords.latitude))
        setLng(String(pos.coords.longitude))
        setLocating(false)
      },
      (err) => {
        setLocating(false)
        setMsg({ ok: false, text: err.message || 'Could not get your location.' })
      },
    )
  }

  async function add(e: FormEvent) {
    e.preventDefault()
    if (!name.trim() || !hasCoords) {
      setMsg({ ok: false, text: 'Enter a name and valid latitude/longitude.' })
      return
    }
    const radNum = parseFloat(radius)
    setBusy(true)
    setMsg(null)
    const res = await createOffice(cid, name.trim(), latNum, lngNum, Number.isFinite(radNum) ? radNum : 100)
    setBusy(false)
    setMsg({ ok: res.ok, text: res.message })
    if (res.ok) {
      setName('')
      setLat('')
      setLng('')
      setRadius('100')
      reload()
    }
  }

  if (loading) return <Spinner />
  if (error || !data) return <ErrorState />

  return (
    <>
      <PageHeader title="Sites & Geofences" subtitle="Define office locations and check-in radius" />

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="p-5">
          <h2 className="mb-4 text-base font-bold text-slate-900">Existing sites</h2>
          {data.length === 0 ? (
            <EmptyState title="No sites yet" subtitle="Add your first office location below." />
          ) : (
            <div className="space-y-2">
              {data.map((o) => (
                <div
                  key={o.id}
                  className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 p-3"
                >
                  <div className="min-w-0">
                    <p className="truncate text-sm font-bold text-slate-900">{o.office_name}</p>
                    <p className="truncate text-xs text-slate-500">
                      {o.latitude}, {o.longitude} · {o.radius} m
                    </p>
                  </div>
                  <Button
                    variant="danger"
                    onClick={async () => {
                      await deleteOffice(o.id)
                      reload()
                    }}
                  >
                    Delete
                  </Button>
                </div>
              ))}
            </div>
          )}
        </Card>

        <Card className="p-5">
          <h2 className="mb-4 text-base font-bold text-slate-900">Add a site</h2>
          <form onSubmit={add} className="space-y-3">
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Office name"
              className={input}
            />
            <div className="grid grid-cols-2 gap-3">
              <input
                type="number"
                step="any"
                value={lat}
                onChange={(e) => setLat(e.target.value)}
                placeholder="Latitude"
                className={input}
              />
              <input
                type="number"
                step="any"
                value={lng}
                onChange={(e) => setLng(e.target.value)}
                placeholder="Longitude"
                className={input}
              />
            </div>
            <input
              type="number"
              step="any"
              value={radius}
              onChange={(e) => setRadius(e.target.value)}
              placeholder="Radius (m)"
              className={input}
            />
            <Button type="button" variant="outline" onClick={useMyLocation} disabled={locating}>
              {locating ? 'Locating…' : '📍 Use my location'}
            </Button>

            <p className="text-xs text-slate-500">Click on the map to drop the office pin; the circle previews the geofence.</p>
            <OfficeMap
              lat={latNum}
              lng={lngNum}
              radius={parseFloat(radius) || 0}
              onPick={(la, lo) => {
                setLat(la.toFixed(6))
                setLng(lo.toFixed(6))
              }}
            />

            {msg && (
              <p className={`text-sm ${msg.ok ? 'text-emerald-600' : 'text-rose-600'}`}>{msg.text}</p>
            )}
            <Button type="submit" disabled={busy}>
              {busy ? 'Adding…' : 'Add Office'}
            </Button>
          </form>
        </Card>
      </div>
    </>
  )
}
