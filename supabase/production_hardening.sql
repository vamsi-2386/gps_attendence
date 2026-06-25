-- =====================================================================
-- Lumenor HRMS — Production Hardening SQL
-- Run in: Supabase Dashboard → SQL Editor  (the anon/publishable key cannot
-- execute DDL via PostgREST, so these must be run here).
-- =====================================================================

-- ---------------------------------------------------------------------
-- BLOCK A — Performance indexes (SAFE: apply now, no app impact)
-- ---------------------------------------------------------------------
create index if not exists idx_att_emp_ts        on public.attendance_logs(employee_id, timestamp desc);
create index if not exists idx_att_company_status on public.attendance_logs(company_id, attendance_status);
create index if not exists idx_att_company_ts     on public.attendance_logs(company_id, timestamp desc);
create index if not exists idx_pe_employee        on public.project_employees(employee_id);
create index if not exists idx_pe_subject         on public.project_employees(subject_id);
create index if not exists idx_emp_company        on public.employees(company_id);
create index if not exists idx_emp_code           on public.employees(employee_code);
create index if not exists idx_offices_company    on public.offices(company_id);
create index if not exists idx_subjects_company   on public.subjects(company_id);
create index if not exists idx_leaves_company     on public.leave_requests(company_id);

-- ---------------------------------------------------------------------
-- BLOCK B — Row Level Security (multi-tenant isolation)
--
-- ⚠️ PREREQUISITE — DO NOT RUN UNTIL AUTH IS IN PLACE.
-- These policies isolate rows by company using a `company_id` claim in the
-- caller's JWT. They only work once BOTH clients authenticate via Supabase
-- Auth (not the raw anon key) AND the JWT carries company_id. Applying this
-- before that is done will DENY ALL requests from the current anon-key app
-- and break it. See docs/PRODUCTION_HARDENING.md for the auth migration.
-- ---------------------------------------------------------------------

-- 1) Custom access-token hook helper: reads company_id from the JWT.
create or replace function public.jwt_company_id()
returns bigint language sql stable as $$
  select nullif(current_setting('request.jwt.claims', true)::json ->> 'company_id', '')::bigint
$$;

-- 2) Enable RLS on every tenant table.
alter table public.companys         enable row level security;
alter table public.employees        enable row level security;
alter table public.offices          enable row level security;
alter table public.subjects         enable row level security;
alter table public.project_employees enable row level security;
alter table public.attendance_logs  enable row level security;
alter table public.leave_requests   enable row level security;

-- 3) Per-company policies (read + write scoped to the caller's company).
create policy company_self on public.companys
  for all using (id = public.jwt_company_id()) with check (id = public.jwt_company_id());

create policy emp_by_company on public.employees
  for all using (company_id = public.jwt_company_id()) with check (company_id = public.jwt_company_id());

create policy off_by_company on public.offices
  for all using (company_id = public.jwt_company_id()) with check (company_id = public.jwt_company_id());

create policy sub_by_company on public.subjects
  for all using (company_id = public.jwt_company_id()) with check (company_id = public.jwt_company_id());

create policy leave_by_company on public.leave_requests
  for all using (company_id = public.jwt_company_id()) with check (company_id = public.jwt_company_id());

create policy att_by_company on public.attendance_logs
  for all using (company_id = public.jwt_company_id()) with check (company_id = public.jwt_company_id());

-- project_employees has no company_id; scope via the employee's company.
create policy pe_by_company on public.project_employees
  for all using (
    exists (select 1 from public.employees e
            where e.employee_id = project_employees.employee_id
              and e.company_id = public.jwt_company_id())
  );

-- ---------------------------------------------------------------------
-- ROLLBACK (if RLS breaks access during the migration)
-- ---------------------------------------------------------------------
-- alter table public.attendance_logs disable row level security;  -- repeat per table
