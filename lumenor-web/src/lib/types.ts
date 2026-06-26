export type Role = 'company' | 'manager' | 'hr'

export interface Session {
  role: Role
  companyId: number
  name: string
  username: string
}

export interface Company {
  id: number
  name: string
  company_invite_code?: string | null
  office_lat?: number | null
  office_lng?: number | null
  office_radius?: number | null
}

export interface Employee {
  employee_id: number
  employee_code: string
  name: string
  designation?: string | null
  role?: string | null
  daily_rate?: number | null
  office_id?: number | null
  mobile?: string | null
  email?: string | null
  photo_url?: string | null
}

export interface AttendanceLog {
  id: number
  employee_id: number
  employee_name?: string | null
  subject_id?: number | null
  site_id?: number | null
  check_in_time?: string | null
  check_out_time?: string | null
  checkout_time?: string | null
  timestamp?: string | null
  worked_hours?: number | null
  attendance_status?: string | null
  geofence_status?: string | null
  is_present?: boolean | null
  latitude?: number | null
  longitude?: number | null
}

export interface LeaveRequest {
  id: number
  employee_id: number
  employee_name?: string
  start_date: string
  end_date: string
  reason?: string | null
  status: string
  created_at?: string | null
}

export interface StaffAccount {
  id: number
  name: string
  email?: string | null
  username: string
  role: string
  created_at?: string | null
}

export interface Project {
  subject_id: number
  subject_code: string
  name: string
  section?: string | null
  total_employees?: number
  total_classes?: number
}

export interface Office {
  id: number
  company_id?: number
  office_name: string
  latitude: number
  longitude: number
  radius: number
}

export interface AuditLog {
  id?: number
  action_type: string
  user_id: number
  user_role: string
  details: unknown
  created_at?: string | null
}

export interface VerificationEvent {
  id?: number
  step_name?: string | null
  failure_reason?: string | null
  score?: number | null
  created_at?: string | null
}

export interface Override {
  id: number
  employee_id: number
  company_id: number
  status: string
  hr_notes?: string | null
  verification_events?: VerificationEvent | VerificationEvent[] | null
}

export interface PayrollRow {
  employee_id: number
  employee_code: string
  name: string
  designation: string
  daily_rate: number
  present_days: number
  estimated_pay: number
}
