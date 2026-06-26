import { useState } from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '../lib/auth'

const NAV = [
  { to: '/dashboard', label: 'Dashboard', icon: '📊' },
  { to: '/projects', label: 'Projects', icon: '📋' },
  { to: '/employees', label: 'Employees', icon: '👥' },
  { to: '/attendance', label: 'Records', icon: '🕒' },
  { to: '/offices', label: 'Sites & Geofences', icon: '📍' },
  { to: '/leaves', label: 'Leave Approvals', icon: '🏖️' },
  { to: '/payroll', label: 'Payroll', icon: '💰' },
  { to: '/audit', label: 'Audit Logs', icon: '🔍' },
  { to: '/analytics', label: 'Analytics', icon: '📈' },
  { to: '/overrides', label: 'HR Overrides', icon: '⚖️' },
  { to: '/staff', label: 'Managers & HR', icon: '👔' },
]

export function Layout() {
  const { session, logout } = useAuth()
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)

  function doLogout() {
    logout()
    navigate('/login', { replace: true })
  }

  const roleLabel =
    session?.role === 'company'
      ? 'Company Admin'
      : session?.role === 'hr'
        ? 'HR Admin'
        : 'Manager'

  return (
    <div className="flex min-h-screen">
      <aside
        className={`fixed inset-y-0 left-0 z-40 w-64 transform border-r border-slate-200 bg-white transition-transform md:static md:translate-x-0 ${
          open ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex items-center gap-2 border-b border-slate-100 px-5 py-4">
          <img src="/lumenor.png" alt="Lumenor" className="h-8 w-8 rounded" />
          <div>
            <p className="text-sm font-bold leading-tight text-slate-900">Lumenor HRMS</p>
            <p className="text-xs text-slate-400">Admin Console</p>
          </div>
        </div>
        <nav className="space-y-1 p-3">
          {NAV.map((n) => (
            <NavLink
              key={n.to}
              to={n.to}
              onClick={() => setOpen(false)}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium transition ${
                  isActive ? 'bg-brand text-white' : 'text-slate-600 hover:bg-slate-100'
                }`
              }
            >
              <span aria-hidden>{n.icon}</span>
              {n.label}
            </NavLink>
          ))}
        </nav>
      </aside>

      {open && (
        <div
          className="fixed inset-0 z-30 bg-black/30 md:hidden"
          onClick={() => setOpen(false)}
        />
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-20 flex items-center justify-between gap-3 border-b border-slate-200 bg-white/80 px-4 py-3 backdrop-blur md:px-8">
          <button
            className="rounded-lg p-2 text-xl leading-none text-slate-600 hover:bg-slate-100 md:hidden"
            onClick={() => setOpen(true)}
            aria-label="Open menu"
          >
            ☰
          </button>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-semibold text-slate-800">{session?.name}</p>
            <p className="text-xs text-slate-400">{roleLabel}</p>
          </div>
          <button
            onClick={doLogout}
            className="rounded-xl border border-slate-300 px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          >
            Logout
          </button>
        </header>
        <main className="flex-1 p-4 md:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
