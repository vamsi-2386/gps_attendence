# Running the database migrations (Supabase CLI)

These three migrations live in `supabase/migrations/` and create the constraints
+ table the app needs:

| Migration | What it does |
|-----------|--------------|
| `…_employee_code_unique.sql` | UNIQUE constraint on `employees.employee_code` |
| `…_attendance_one_per_day.sql` | One check-in per employee per local day |
| `…_staff_accounts.sql` | `staff_accounts` table for Manager/HR logins |

## Why you have to run the push step
DDL (`CREATE TABLE` / `ALTER`) requires **database-level credentials** — your
project's **database password** (and a Supabase access token). The app only ships
the *publishable/anon* key, which deliberately cannot run DDL. For security, those
credentials are never stored in the repo and are entered only by you.

## One-time: authenticate + link
```powershell
# Supabase CLI is installed at: %LOCALAPPDATA%\supabase-cli\supabase.exe
# (added to PATH; open a new terminal if `supabase` isn't found yet)

supabase login                                   # opens browser to authenticate
supabase link --project-ref hpooyhqbooruuvhziwei # links this repo to your project
```

## Apply the migrations
```powershell
supabase db push
```
`db push` applies only the migrations not yet recorded on the remote, and will
prompt for your **database password** (Supabase Dashboard → Project Settings →
Database → Database password). That's the only secret you enter, and it stays on
your machine.

### Fully non-interactive (optional, e.g. CI)
```powershell
$env:SUPABASE_ACCESS_TOKEN = "<token from https://supabase.com/dashboard/account/tokens>"
supabase link --project-ref hpooyhqbooruuvhziwei -p "<DB password>"
supabase db push -p "<DB password>"
```

## Zero-setup alternative (no CLI)
Open the Supabase Dashboard → **SQL Editor**, paste the contents of each file in
`supabase/migrations/` (in filename order), and run. Takes ~2 minutes.
