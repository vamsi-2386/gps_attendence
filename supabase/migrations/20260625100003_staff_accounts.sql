-- ============================================================================
-- Manager / HR staff accounts  (run once in the Supabase SQL editor)
-- ----------------------------------------------------------------------------
-- WHY: the company admin can now create Manager and HR profiles in the web
-- dashboard. These accounts log in on BOTH the web admin and the mobile app
-- (Manager / HR Admin roles) with their own username + bcrypt password —
-- separate from the single company login.
--
-- Passwords are bcrypt-hashed by the app (never stored in plain text).
-- ============================================================================

CREATE TABLE IF NOT EXISTS staff_accounts (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id  bigint NOT NULL,
    name        text   NOT NULL,
    email       text,
    username    text   NOT NULL UNIQUE,
    password    text   NOT NULL,                 -- bcrypt hash
    role        text   NOT NULL DEFAULT 'manager' -- 'manager' | 'hr'
                CHECK (role IN ('manager', 'hr')),
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- Fast lookup by company (web list) and by username (login).
CREATE INDEX IF NOT EXISTS idx_staff_accounts_company ON staff_accounts (company_id);
