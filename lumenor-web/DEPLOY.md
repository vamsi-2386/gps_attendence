# Lumenor HRMS — Web App (React + Vite)

A company-only admin web app (a modern alternative to the Streamlit dashboard),
reading the **same Supabase database**. The Streamlit app stays as-is; this is a
separate, fully responsive site meant for Vercel.

## What it does
- Login for **Company / Manager / HR** (same credentials as the Streamlit portal
  and the mobile app — verified with bcrypt against `companys` + `staff_accounts`).
- Dashboard (live stats + team status), Employees, Attendance Records,
  Leave Approvals (approve/reject), HR Overrides (approve/reject flagged
  check-ins), and Managers & HR account management.
- Responsive on phones, tablets and desktop.

## Local development
```bash
cd lumenor-web
npm install
npm run dev          # http://localhost:5173
```

## Environment variables
The Supabase URL + anon (publishable) key are baked in as defaults, so it runs
out of the box. To override (recommended for your own project), copy `.env.example`
to `.env.local`, and add the same two vars in Vercel → Project → Settings →
Environment Variables:
```
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
```

## Deploy to Vercel (you run this — it needs your Vercel account)
```bash
cd lumenor-web
npx vercel           # first run: log in (browser) + create/link the project
npx vercel --prod    # production deploy → gives you the live URL
```
Vercel auto-detects Vite (see `vercel.json`): build `vite build`, output `dist`,
SPA routing handled by the rewrite. I can't run `vercel login` for you (it
authenticates your account), so this step is yours — everything else is ready.

## Security note (same model as the rest of the pilot)
Login verifies bcrypt **client-side** against rows read with the anon key (no
RLS yet) — consistent with the current single-tenant pilot. When you do the
Supabase Auth + RLS migration, move this verification server-side (a Vercel
serverless function) for defense in depth.
