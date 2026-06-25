-- ============================================================================
-- One attendance record per employee per local day  (run in Supabase SQL editor)
-- ----------------------------------------------------------------------------
-- WHY: the mobile app already prevents a second check-in per day in code
-- (HrmsRepository.todayAttendance), but two devices/sessions or a direct API
-- call could still insert duplicates. This partial unique index enforces the
-- rule at the database level — the single source of truth.
--
-- The app stores check_in_time in UTC and buckets the "day" in the device's
-- LOCAL timezone (IST). To match that exactly, the index keys on the IST
-- calendar date, so a 11pm-IST and a 1am-IST check-in count as different days
-- the same way the app sees them.
--
-- Only rows that actually have a check_in_time are constrained (legacy/null
-- rows are ignored), so this won't fail on historical data.
-- ============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS attendance_one_per_employee_per_day
  ON attendance_logs (
    employee_id,
    ((check_in_time AT TIME ZONE 'Asia/Kolkata')::date)
  )
  WHERE check_in_time IS NOT NULL;
