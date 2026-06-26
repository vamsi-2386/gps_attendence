import bcrypt from 'bcryptjs'
import { supabase } from './supabase'
import type {
  Employee,
  AttendanceLog,
  LeaveRequest,
  StaffAccount,
  Project,
  Office,
  AuditLog,
  Override,
  Company,
  PayrollRow,
} from './types'
import { localDateKey } from './format'

const ATT_COLS =
  'id, employee_id, employee_name, company_id, subject_id, site_id, timestamp, ' +
  'check_in_time, check_out_time, checkout_time, worked_hours, is_present, ' +
  'latitude, longitude, location_status, attendance_status, geofence_status, created_at'

// ---- Company -------------------------------------------------------------

export async function getCompany(companyId: number): Promise<Company | null> {
  const { data, error } = await supabase
    .from('companys')
    .select('id, name, company_invite_code, office_lat, office_lng, office_radius')
    .eq('id', companyId)
    .limit(1)
  if (error) throw error
  return (data && data[0]) ? (data[0] as Company) : null
}

// ---- Employees -----------------------------------------------------------

export async function getEmployees(companyId: number): Promise<Employee[]> {
  const base = 'employee_id, employee_code, name, designation, role, daily_rate, office_id, mobile, email'
  // Try with photo_url; if the column doesn't exist yet (migration not run),
  // fall back so the page never breaks.
  let res = await supabase
    .from('employees')
    .select(`${base}, photo_url`)
    .eq('company_id', companyId)
    .order('name')
  if (res.error) {
    res = await supabase.from('employees').select(base).eq('company_id', companyId).order('name')
  }
  if (res.error) throw res.error
  return (res.data ?? []) as Employee[]
}

/** Upload an employee photo to the 'employee-photos' Storage bucket; returns the
 * public URL, or null if Storage isn't set up (best-effort — never blocks
 * registration). */
export async function uploadEmployeePhoto(code: string, file: File): Promise<string | null> {
  try {
    const path = `${code.replace(/[^A-Za-z0-9_-]/g, '_')}.jpg`
    const { error } = await supabase.storage
      .from('employee-photos')
      .upload(path, file, { upsert: true, contentType: file.type || 'image/jpeg' })
    if (error) return null
    const { data } = supabase.storage.from('employee-photos').getPublicUrl(path)
    return data?.publicUrl ?? null
  } catch {
    return null
  }
}

/** Best-effort: store the photo URL on the employee (ignored if column absent). */
export async function setEmployeePhoto(employeeId: number, url: string): Promise<void> {
  try {
    await supabase.from('employees').update({ photo_url: url }).eq('employee_id', employeeId)
  } catch {
    /* photo_url column not present yet — ignore */
  }
}

export async function registerEmployee(input: {
  companyId: number
  employeeCode: string
  name: string
  designation: string
  dailyRate: number
  officeId?: number | null
  mobile?: string
  email?: string
}): Promise<{ ok: boolean; message: string; employeeId?: number }> {
  if (!input.employeeCode.trim() || !input.name.trim()) {
    return { ok: false, message: 'Employee code and name are required.' }
  }
  const { data: dup } = await supabase
    .from('employees')
    .select('employee_id')
    .eq('employee_code', input.employeeCode.trim())
  if (dup && dup.length) return { ok: false, message: 'That employee code already exists.' }
  const { data, error } = await supabase
    .from('employees')
    .insert({
      company_id: input.companyId,
      employee_code: input.employeeCode.trim(),
      name: input.name.trim(),
      designation: input.designation.trim() || 'Employee',
      daily_rate: input.dailyRate || 0,
      role: 'employee',
      office_id: input.officeId ?? null,
      mobile: input.mobile?.trim() || null,
      email: input.email?.trim() || null,
    })
    .select('employee_id')
    .single()
  if (error) return { ok: false, message: error.message }
  return { ok: true, message: 'Employee registered.', employeeId: data?.employee_id as number }
}

export async function updateDesignation(employeeId: number, designation: string): Promise<void> {
  const { error } = await supabase.from('employees').update({ designation }).eq('employee_id', employeeId)
  if (error) throw error
}

export async function updateDailyRate(employeeId: number, rate: number): Promise<void> {
  const { error } = await supabase.from('employees').update({ daily_rate: rate }).eq('employee_id', employeeId)
  if (error) throw error
}

// ---- Attendance ----------------------------------------------------------

export async function getAttendance(companyId: number, limit = 1000): Promise<AttendanceLog[]> {
  const { data, error } = await supabase
    .from('attendance_logs')
    .select(ATT_COLS)
    .eq('company_id', companyId)
    .order('timestamp', { ascending: false })
    .limit(limit)
  if (error) throw error
  return (data ?? []) as AttendanceLog[]
}

export async function reviewFlaggedAttendance(id: number, approved: boolean): Promise<void> {
  const patch = approved
    ? { is_present: true, attendance_status: 'Present', location_status: 'Present' }
    : { is_present: false, attendance_status: 'Rejected', location_status: 'Rejected' }
  const { error } = await supabase.from('attendance_logs').update(patch).eq('id', id)
  if (error) throw error
}

// ---- Projects (subjects) -------------------------------------------------

export async function getProjects(companyId: number): Promise<Project[]> {
  const { data, error } = await supabase
    .from('subjects')
    .select('subject_id, subject_code, name, section')
    .eq('company_id', companyId)
    .order('subject_id')
  if (error) throw error
  const subjects = (data ?? []) as Project[]
  const { count: empCount } = await supabase
    .from('employees')
    .select('employee_id', { count: 'exact', head: true })
    .eq('company_id', companyId)
  for (const s of subjects) {
    s.total_employees = empCount ?? 0
    const { data: logs } = await supabase
      .from('attendance_logs')
      .select('timestamp')
      .eq('subject_id', s.subject_id)
    const days = new Set((logs ?? []).map((l: { timestamp: string }) => l.timestamp))
    s.total_classes = days.size
  }
  return subjects
}

export async function createProject(
  companyId: number,
  name: string,
  subjectCode: string,
  section: string,
): Promise<{ ok: boolean; message: string }> {
  if (!name.trim() || !subjectCode.trim()) return { ok: false, message: 'Name and code are required.' }
  const { error } = await supabase.from('subjects').insert({
    company_id: companyId,
    name: name.trim(),
    subject_code: subjectCode.trim(),
    section: section.trim() || null,
  })
  if (error) return { ok: false, message: error.message }
  return { ok: true, message: 'Project created.' }
}

// ---- Offices (geofences) -------------------------------------------------

export async function getOffices(companyId: number): Promise<Office[]> {
  const { data, error } = await supabase
    .from('offices')
    .select('id, company_id, office_name, latitude, longitude, radius')
    .eq('company_id', companyId)
    .order('office_name')
  if (error) throw error
  return (data ?? []) as Office[]
}

export async function createOffice(
  companyId: number,
  officeName: string,
  latitude: number,
  longitude: number,
  radius: number,
): Promise<{ ok: boolean; message: string }> {
  if (!officeName.trim()) return { ok: false, message: 'Office name is required.' }
  const { error } = await supabase.from('offices').insert({
    company_id: companyId,
    office_name: officeName.trim(),
    latitude,
    longitude,
    radius,
    timezone: 'UTC',
  })
  if (error) return { ok: false, message: error.message }
  return { ok: true, message: 'Office created.' }
}

export async function deleteOffice(id: number): Promise<void> {
  const { error } = await supabase.from('offices').delete().eq('id', id)
  if (error) throw error
}

// ---- Leave ---------------------------------------------------------------

export async function getLeaves(companyId: number, status?: string): Promise<LeaveRequest[]> {
  let q = supabase
    .from('leave_requests')
    .select('id, employee_id, company_id, start_date, end_date, reason, status, created_at')
    .eq('company_id', companyId)
  if (status) q = q.eq('status', status)
  const { data, error } = await q.order('created_at', { ascending: false })
  if (error) throw error
  const leaves = (data ?? []) as LeaveRequest[]
  const ids = [...new Set(leaves.map((l) => l.employee_id))]
  if (ids.length) {
    const { data: emps } = await supabase.from('employees').select('employee_id, name').in('employee_id', ids)
    const map = new Map((emps ?? []).map((e: { employee_id: number; name: string }) => [e.employee_id, e.name]))
    leaves.forEach((l) => {
      l.employee_name = map.get(l.employee_id) ?? 'Unknown'
    })
  }
  return leaves
}

export async function setLeaveStatus(id: number, status: 'Approved' | 'Rejected'): Promise<void> {
  const { error } = await supabase.from('leave_requests').update({ status }).eq('id', id)
  if (error) throw error
}

// ---- Audit ---------------------------------------------------------------

export async function getAuditLogs(companyId: number): Promise<AuditLog[]> {
  const { data, error } = await supabase
    .from('audit_logs')
    .select('*')
    .eq('user_id', companyId)
    .order('created_at', { ascending: false })
    .limit(100)
  if (error) throw error
  return (data ?? []) as AuditLog[]
}

export async function logAudit(
  actionType: string,
  companyId: number,
  details: Record<string, unknown>,
): Promise<void> {
  await supabase
    .from('audit_logs')
    .insert({ action_type: actionType, user_id: companyId, user_role: 'company', details })
}

// ---- Overrides (verification queue) --------------------------------------

export async function getOverrides(companyId: number): Promise<Override[]> {
  const { data, error } = await supabase
    .from('attendance_overrides')
    .select('*, verification_events(*)')
    .eq('company_id', companyId)
    .eq('status', 'Pending')
  if (error) throw error
  return (data ?? []) as Override[]
}

export async function reviewOverride(
  id: number,
  approved: boolean,
  notes: string,
  companyId: number,
): Promise<void> {
  const { error } = await supabase
    .from('attendance_overrides')
    .update({
      status: approved ? 'Approved' : 'Rejected',
      hr_notes: notes,
      reviewer_id: companyId,
      resolved_at: new Date().toISOString(),
    })
    .eq('id', id)
  if (error) throw error
}

// ---- Staff (managers / HR) ----------------------------------------------

export async function getStaff(companyId: number): Promise<StaffAccount[]> {
  const { data, error } = await supabase
    .from('staff_accounts')
    .select('id, name, email, username, role, created_at')
    .eq('company_id', companyId)
    .order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []) as StaffAccount[]
}

export async function createStaff(
  companyId: number,
  name: string,
  username: string,
  password: string,
  role: string,
  email?: string,
): Promise<{ ok: boolean; message: string }> {
  if (!name.trim() || !username.trim() || !password) {
    return { ok: false, message: 'Name, username and password are required.' }
  }
  const { data: existing } = await supabase.from('staff_accounts').select('id').eq('username', username.trim())
  if (existing && existing.length) return { ok: false, message: 'That username is already taken.' }
  const hash = bcrypt.hashSync(password, 10)
  const { error } = await supabase.from('staff_accounts').insert({
    company_id: companyId,
    name: name.trim(),
    email: email?.trim() || null,
    username: username.trim(),
    password: hash,
    role,
  })
  if (error) return { ok: false, message: error.message }
  return { ok: true, message: `${role === 'hr' ? 'HR' : 'Manager'} account created.` }
}

export async function deleteStaff(id: number): Promise<void> {
  const { error } = await supabase.from('staff_accounts').delete().eq('id', id)
  if (error) throw error
}

// ---- Payroll (computed client-side, mirrors Streamlit) -------------------

export function computePayroll(employees: Employee[], attendance: AttendanceLog[]): PayrollRow[] {
  return employees.map((e) => {
    const days = new Set<string>()
    for (const a of attendance) {
      if (a.employee_id === e.employee_id && a.is_present) {
        const key = localDateKey(a.check_in_time ?? a.timestamp)
        if (key) days.add(key)
      }
    }
    const rate = Number(e.daily_rate ?? 0) || 0
    return {
      employee_id: e.employee_id,
      employee_code: e.employee_code,
      name: e.name,
      designation: e.designation || 'Employee',
      daily_rate: rate,
      present_days: days.size,
      estimated_pay: days.size * rate,
    }
  })
}
