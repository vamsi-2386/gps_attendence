import type { ReactNode } from 'react'

export function Spinner() {
  return (
    <div className="flex items-center justify-center py-16">
      <div className="h-8 w-8 animate-spin rounded-full border-2 border-brand border-t-transparent" />
    </div>
  )
}

export function Card({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`rounded-2xl border border-slate-200 bg-white shadow-sm ${className}`}>
      {children}
    </div>
  )
}

export function PageHeader({
  title,
  subtitle,
  action,
}: {
  title: string
  subtitle?: string
  action?: ReactNode
}) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-slate-500">{subtitle}</p>}
      </div>
      {action}
    </div>
  )
}

const TONE_TEXT: Record<string, string> = {
  brand: 'text-brand',
  green: 'text-emerald-600',
  red: 'text-rose-600',
  amber: 'text-amber-600',
  blue: 'text-sky-600',
  slate: 'text-slate-700',
}

export function StatCard({
  label,
  value,
  tone = 'brand',
  icon,
}: {
  label: string
  value: ReactNode
  tone?: keyof typeof TONE_TEXT
  icon?: ReactNode
}) {
  return (
    <Card className="p-5">
      <div className="flex items-center justify-between">
        <span className={`text-3xl font-extrabold ${TONE_TEXT[tone]}`}>{value}</span>
        {icon && <span className={`text-2xl ${TONE_TEXT[tone]}`}>{icon}</span>}
      </div>
      <p className="mt-1 text-sm text-slate-500">{label}</p>
    </Card>
  )
}

const BADGE: Record<string, string> = {
  present: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  approved: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  flagged: 'bg-amber-50 text-amber-700 ring-amber-200',
  pending: 'bg-amber-50 text-amber-700 ring-amber-200',
  rejected: 'bg-rose-50 text-rose-700 ring-rose-200',
  absent: 'bg-rose-50 text-rose-700 ring-rose-200',
  slate: 'bg-slate-100 text-slate-600 ring-slate-200',
}

export function Badge({ children, tone = 'slate' }: { children: ReactNode; tone?: string }) {
  const cls = BADGE[tone.toLowerCase()] ?? BADGE.slate
  return (
    <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ${cls}`}>
      {children}
    </span>
  )
}

const VARIANTS: Record<string, string> = {
  primary: 'bg-brand text-white hover:bg-brand-dark',
  outline: 'border border-slate-300 text-slate-700 hover:bg-slate-50',
  danger: 'bg-rose-600 text-white hover:bg-rose-700',
  success: 'bg-emerald-600 text-white hover:bg-emerald-700',
  ghost: 'text-slate-600 hover:bg-slate-100',
}

export function Button({
  children,
  onClick,
  variant = 'primary',
  disabled,
  type = 'button',
  className = '',
}: {
  children: ReactNode
  onClick?: () => void
  variant?: keyof typeof VARIANTS
  disabled?: boolean
  type?: 'button' | 'submit'
  className?: string
}) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`inline-flex items-center justify-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition disabled:cursor-not-allowed disabled:opacity-50 ${VARIANTS[variant]} ${className}`}
    >
      {children}
    </button>
  )
}

export function EmptyState({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <Card className="p-12 text-center">
      <p className="text-lg font-semibold text-slate-700">{title}</p>
      {subtitle && <p className="mt-1 text-sm text-slate-500">{subtitle}</p>}
    </Card>
  )
}

export function ErrorState({ message }: { message?: string }) {
  return (
    <Card className="p-8 text-center">
      <p className="text-base font-semibold text-rose-600">Couldn’t load data</p>
      <p className="mt-1 text-sm text-slate-500">{message ?? 'Check your connection and try again.'}</p>
    </Card>
  )
}
