-- ============================================================================
-- Enforce unique employee codes  (run once in the Supabase SQL editor)
-- ----------------------------------------------------------------------------
-- WHY: two employees rows shared the code "EMP-4G5" (ids 16 and 17). With no
-- unique constraint, login (employeeByCode) resolved to whichever row Postgres
-- returned first, so a person could log in as the id that owned NO attendance
-- while their real records sat on the other id. That produced the
-- "logged in but attendance not reflecting" + duplicate-record symptoms.
--
-- The duplicate rows have already been cleaned up from the app, so this
-- constraint will apply cleanly. After this runs, an attempt to insert a second
-- row with an existing code fails at the database level (defence in depth on
-- top of the app-layer guard in HrmsRepository.createEmployee).
--
-- Pre-flight check (optional) — must return zero rows before adding the
-- constraint:
--   SELECT employee_code, count(*)
--   FROM employees
--   GROUP BY employee_code
--   HAVING count(*) > 1;
-- ============================================================================

ALTER TABLE employees
  ADD CONSTRAINT employees_employee_code_key UNIQUE (employee_code);
