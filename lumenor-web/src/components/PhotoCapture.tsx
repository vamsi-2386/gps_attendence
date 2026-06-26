import { useEffect, useRef, useState, type ChangeEvent } from 'react'
import { Button } from './ui'

/**
 * Capture an employee photo via the device camera, or upload an image file.
 * Calls onChange with the chosen File (and a preview URL) or null when cleared.
 */
export function PhotoCapture({
  onChange,
}: {
  onChange: (file: File | null, preview: string | null) => void
}) {
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const [camOn, setCamOn] = useState(false)
  const [preview, setPreview] = useState<string | null>(null)
  const [err, setErr] = useState<string | null>(null)

  useEffect(() => () => stopCam(), [])

  function stopCam() {
    streamRef.current?.getTracks().forEach((t) => t.stop())
    streamRef.current = null
  }

  async function startCam() {
    setErr(null)
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' } })
      streamRef.current = stream
      setCamOn(true)
      setTimeout(() => {
        if (videoRef.current) {
          videoRef.current.srcObject = stream
          void videoRef.current.play()
        }
      }, 50)
    } catch {
      setErr('Could not access the camera. Use "Upload photo" instead.')
    }
  }

  function cancelCam() {
    stopCam()
    setCamOn(false)
  }

  function capture() {
    const v = videoRef.current
    if (!v) return
    const w = v.videoWidth || 480
    const h = v.videoHeight || 480
    const canvas = document.createElement('canvas')
    canvas.width = w
    canvas.height = h
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.drawImage(v, 0, 0, w, h)
    canvas.toBlob(
      (blob) => {
        if (!blob) return
        const file = new File([blob], 'photo.jpg', { type: 'image/jpeg' })
        const url = URL.createObjectURL(blob)
        setPreview(url)
        onChange(file, url)
        cancelCam()
      },
      'image/jpeg',
      0.85,
    )
  }

  function onFile(e: ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0]
    if (!f) return
    const url = URL.createObjectURL(f)
    setPreview(url)
    onChange(f, url)
  }

  function clear() {
    setPreview(null)
    onChange(null, null)
  }

  return (
    <div className="space-y-2">
      <label className="block text-xs font-semibold uppercase tracking-wide text-slate-500">
        Photo
      </label>

      {preview ? (
        <div className="flex items-center gap-3">
          <img
            src={preview}
            alt="Employee"
            className="h-24 w-24 rounded-xl border border-slate-200 object-cover"
          />
          <Button variant="ghost" onClick={clear}>
            Remove
          </Button>
        </div>
      ) : camOn ? (
        <div className="space-y-2">
          <video
            ref={videoRef}
            className="h-48 w-full rounded-xl border border-slate-200 bg-slate-900 object-cover"
            playsInline
            muted
          />
          <div className="flex gap-2">
            <Button variant="primary" onClick={capture}>
              Capture
            </Button>
            <Button variant="outline" onClick={cancelCam}>
              Cancel
            </Button>
          </div>
        </div>
      ) : (
        <div className="flex flex-wrap items-center gap-2">
          <Button variant="outline" onClick={startCam}>
            📷 Use camera
          </Button>
          <label className="inline-flex cursor-pointer items-center rounded-xl border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50">
            Upload photo
            <input type="file" accept="image/*" className="hidden" onChange={onFile} />
          </label>
        </div>
      )}

      {err && <p className="text-sm text-rose-600">{err}</p>}
    </div>
  )
}
