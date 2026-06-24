-- Lumenor HRMS Database Schema
-- This SQL script creates all required tables for the Supabase backend

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Companies Table
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  registration_number TEXT UNIQUE NOT NULL,
  email_domain TEXT,
  logo_url TEXT,
  address TEXT NOT NULL,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  country TEXT,
  phone_number TEXT,
  website TEXT,
  industry TEXT,
  total_employees INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create index on registration_number for faster lookups
CREATE INDEX IF NOT EXISTS idx_companies_registration_number ON companies(registration_number);
CREATE INDEX IF NOT EXISTS idx_companies_is_active ON companies(is_active);

-- Employees Table
CREATE TABLE IF NOT EXISTS employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone_number TEXT,
  employee_id TEXT UNIQUE NOT NULL,
  designation TEXT NOT NULL,
  department TEXT,
  profile_image_url TEXT,
  face_embedding_id TEXT,
  voice_embedding_id TEXT,
  is_face_enrolled BOOLEAN DEFAULT false,
  is_voice_enrolled BOOLEAN DEFAULT false,
  daily_rate DECIMAL(10, 2),
  date_of_joining TIMESTAMP NOT NULL,
  date_of_birth TIMESTAMP,
  role TEXT DEFAULT 'employee' CHECK (role IN ('employee', 'manager', 'hr', 'admin')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes on employees
CREATE INDEX IF NOT EXISTS idx_employees_company_id ON employees(company_id);
CREATE INDEX IF NOT EXISTS idx_employees_employee_id ON employees(employee_id);
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_employees_is_active ON employees(is_active);
CREATE INDEX IF NOT EXISTS idx_employees_role ON employees(role);

-- Offices Table
CREATE TABLE IF NOT EXISTS offices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT,
  state TEXT,
  country TEXT,
  zip_code TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  geofence_radius DOUBLE PRECISION DEFAULT 100.0,
  contact TEXT,
  description TEXT,
  is_headquarters BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes on offices
CREATE INDEX IF NOT EXISTS idx_offices_company_id ON offices(company_id);
CREATE INDEX IF NOT EXISTS idx_offices_is_active ON offices(is_active);
CREATE INDEX IF NOT EXISTS idx_offices_is_headquarters ON offices(is_headquarters);

-- Attendance Logs Table
CREATE TABLE IF NOT EXISTS attendance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  office_id UUID REFERENCES offices(id) ON DELETE SET NULL,
  check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
  check_out_time TIMESTAMP WITH TIME ZONE,
  check_in_location TEXT NOT NULL,
  check_out_location TEXT,
  check_in_latitude DOUBLE PRECISION NOT NULL,
  check_in_longitude DOUBLE PRECISION NOT NULL,
  check_out_latitude DOUBLE PRECISION,
  check_out_longitude DOUBLE PRECISION,
  is_inside_geofence BOOLEAN DEFAULT true,
  status TEXT DEFAULT 'checked_in' CHECK (status IN ('checked_in', 'checked_out', 'absent', 'late')),
  notes TEXT,
  is_face_verified BOOLEAN DEFAULT false,
  is_voice_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes on attendance_logs
CREATE INDEX IF NOT EXISTS idx_attendance_logs_employee_id ON attendance_logs(employee_id);
CREATE INDEX IF NOT EXISTS idx_attendance_logs_company_id ON attendance_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_attendance_logs_check_in_time ON attendance_logs(check_in_time);
CREATE INDEX IF NOT EXISTS idx_attendance_logs_status ON attendance_logs(status);
CREATE INDEX IF NOT EXISTS idx_attendance_logs_employee_date ON attendance_logs(employee_id, DATE(check_in_time));

-- Leave Requests Table
CREATE TABLE IF NOT EXISTS leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  leave_type TEXT NOT NULL CHECK (leave_type IN ('casual', 'sick', 'earned', 'unpaid', 'maternity')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  reason TEXT NOT NULL,
  attachment_url TEXT,
  approver_comments TEXT,
  approved_by_employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
  approval_date TIMESTAMP WITH TIME ZONE,
  number_of_days INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes on leave_requests
CREATE INDEX IF NOT EXISTS idx_leave_requests_employee_id ON leave_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_company_id ON leave_requests(company_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_start_date ON leave_requests(start_date);
CREATE INDEX IF NOT EXISTS idx_leave_requests_employee_status ON leave_requests(employee_id, status);

-- Face Embeddings Table
CREATE TABLE IF NOT EXISTS face_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  embedding VECTOR(128),
  embedding_version TEXT DEFAULT '1.0',
  confidence DOUBLE PRECISION,
  face_image_url TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes on face_embeddings
CREATE INDEX IF NOT EXISTS idx_face_embeddings_employee_id ON face_embeddings(employee_id);
CREATE INDEX IF NOT EXISTS idx_face_embeddings_is_primary ON face_embeddings(is_primary);

-- Voice Embeddings Table
CREATE TABLE IF NOT EXISTS voice_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  embedding VECTOR(128),
  embedding_version TEXT DEFAULT '1.0',
  confidence DOUBLE PRECISION,
  voice_sample_url TEXT,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes on voice_embeddings
CREATE INDEX IF NOT EXISTS idx_voice_embeddings_employee_id ON voice_embeddings(employee_id);
CREATE INDEX IF NOT EXISTS idx_voice_embeddings_is_primary ON voice_embeddings(is_primary);

-- Enable Row Level Security (RLS)
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE face_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_embeddings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for employees
CREATE POLICY "Enable read for authenticated users" ON employees
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON employees
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for own record" ON employees
  FOR UPDATE USING (id = auth.uid());

-- RLS Policies for attendance_logs
CREATE POLICY "Enable read for authenticated users" ON attendance_logs
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON attendance_logs
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for leave_requests
CREATE POLICY "Enable read for authenticated users" ON leave_requests
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON leave_requests
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for own record or manager" ON leave_requests
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Create function to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offices_updated_at BEFORE UPDATE ON offices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_logs_updated_at BEFORE UPDATE ON attendance_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leave_requests_updated_at BEFORE UPDATE ON leave_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_face_embeddings_updated_at BEFORE UPDATE ON face_embeddings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_voice_embeddings_updated_at BEFORE UPDATE ON voice_embeddings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create view for daily attendance summary
CREATE OR REPLACE VIEW daily_attendance_summary AS
SELECT
  DATE(al.check_in_time) as date,
  al.company_id,
  al.employee_id,
  e.first_name,
  e.last_name,
  COUNT(*) as check_ins,
  COUNT(CASE WHEN al.status = 'late' THEN 1 END) as late_count,
  COUNT(CASE WHEN al.status = 'absent' THEN 1 END) as absent_count,
  AVG(EXTRACT(EPOCH FROM (al.check_out_time - al.check_in_time))/3600)::DECIMAL(10,2) as avg_hours
FROM attendance_logs al
JOIN employees e ON al.employee_id = e.id
GROUP BY DATE(al.check_in_time), al.company_id, al.employee_id, e.first_name, e.last_name
ORDER BY date DESC;

-- Create view for pending leave approvals
CREATE OR REPLACE VIEW pending_leave_approvals AS
SELECT
  lr.id,
  lr.employee_id,
  e.first_name,
  e.last_name,
  e.designation,
  lr.start_date,
  lr.end_date,
  lr.leave_type,
  lr.reason,
  lr.number_of_days,
  lr.created_at
FROM leave_requests lr
JOIN employees e ON lr.employee_id = e.id
WHERE lr.status = 'pending'
ORDER BY lr.created_at ASC;

-- Sample data insert (comment out if not needed)
/*
-- Insert a sample company
INSERT INTO companies (name, registration_number, email_domain, address, city, state, country, phone_number)
VALUES ('Lumenor Technologies', 'REG123456', 'lumenor.com', '123 Tech Street', 'Bangalore', 'Karnataka', 'India', '+91-9876543210');

-- Insert sample offices
INSERT INTO offices (company_id, name, address, city, state, country, latitude, longitude, is_headquarters)
SELECT id, 'Main Office', '123 Tech Street', 'Bangalore', 'Karnataka', 'India', 12.9716, 77.5946, true
FROM companies WHERE registration_number = 'REG123456';

-- Insert sample employees
INSERT INTO employees (company_id, email, first_name, last_name, employee_id, designation, department, date_of_joining, daily_rate)
SELECT id, 'john.doe@lumenor.com', 'John', 'Doe', 'EMP001', 'Software Engineer', 'Engineering', now(), 1000
FROM companies WHERE registration_number = 'REG123456';
*/

-- Vacuum analyze to update statistics
VACUUM ANALYZE;

-- Output
SELECT 'Database setup completed successfully' as message;
