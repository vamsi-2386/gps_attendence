import { useEffect } from 'react'
import { MapContainer, TileLayer, Marker, Circle, useMap, useMapEvents } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png'
import markerIcon from 'leaflet/dist/images/marker-icon.png'
import markerShadow from 'leaflet/dist/images/marker-shadow.png'

// Vite bundles the marker images; without this the default pin is broken.
L.Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon2x,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
})

function ClickHandler({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onPick(e.latlng.lat, e.latlng.lng)
    },
  })
  return null
}

function Recenter({ lat, lng }: { lat: number; lng: number }) {
  const map = useMap()
  useEffect(() => {
    if (lat && lng) map.setView([lat, lng])
  }, [lat, lng, map])
  return null
}

/**
 * Interactive geofence picker. Click anywhere to drop/move the office pin; the
 * shaded circle previews the geofence radius in metres.
 */
export function OfficeMap({
  lat,
  lng,
  radius,
  onPick,
}: {
  lat: number
  lng: number
  radius: number
  onPick: (lat: number, lng: number) => void
}) {
  const hasPoint = Number.isFinite(lat) && Number.isFinite(lng) && (lat !== 0 || lng !== 0)
  const center: [number, number] = hasPoint ? [lat, lng] : [20.5937, 78.9629] // India

  return (
    <div className="overflow-hidden rounded-xl border border-slate-200" style={{ height: 300 }}>
      <MapContainer
        center={center}
        zoom={hasPoint ? 16 : 5}
        scrollWheelZoom
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          attribution='&copy; OpenStreetMap contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <ClickHandler onPick={onPick} />
        {hasPoint && <Recenter lat={lat} lng={lng} />}
        {hasPoint && <Marker position={[lat, lng]} />}
        {hasPoint && radius > 0 && (
          <Circle
            center={[lat, lng]}
            radius={radius}
            pathOptions={{ color: '#5b5bf6', fillColor: '#5b5bf6', fillOpacity: 0.12 }}
          />
        )}
      </MapContainer>
    </div>
  )
}
