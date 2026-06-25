# Lumenor HRMS — Production Hardening Guide

## What's already done (this work)
- ✅ Release-signed APK (`CN=Lumenor HRMS`, V2). Keystore `lumenor_hrms_flutter/android/lumenor-release.jks` (password in `key.properties`, git-ignored — **back it up**).
- ✅ Mobile is the single attendance source; Streamlit = dashboards/reports/HR review only.
- ✅ Worked-hours stored in UTC, displayed local; duplicate-day prevention.
- ✅ HR Approve/Reject synced across mobile + Streamlit + Supabase.
- ✅ DB cleaned: dummy companies removed; orphans backfilled; one tenant (company 12).
- ✅ Streamlit latest pushed to `main` (auto-deployed).

## Run now (safe) — database indexes
`supabase/production_hardening.sql` → **BLOCK A**. Paste into Supabase → SQL Editor → Run. No app impact; speeds up dashboard/HR queries. *(Cannot be applied from the app — the anon key can't run DDL.)*

## The remaining hardening: Auth + RLS (a scoped follow-up)
**Why it isn't auto-applied:** both clients connect with the shared **anon/publishable key** — there is no Supabase Auth identity. RLS isolates rows by the caller's identity (JWT claim). Enabling the policies (BLOCK B) before auth exists **denies every request and breaks the app**. This needs Supabase **dashboard** access + a tested client change — it can't be completed safely from a CLI session.

### Migration steps (do in order, in a staging project first)
1. **Company auth users** — for each row in `companys`, create a Supabase Auth user (email = company username) and set `user_metadata.company_id`. Use the **service_role** key or the dashboard (not the anon key).
2. **JWT claim** — add a *Custom Access Token Hook* (Dashboard → Auth → Hooks) that copies `company_id` from user metadata into the JWT. `production_hardening.sql` already defines `public.jwt_company_id()` to read it.
3. **Streamlit** — replace the bcrypt login with `supabase.auth.sign_in_with_password(...)`; use the returned session so PostgREST calls carry the JWT.
4. **Flutter** — sign the device in (company service account, or per-employee Supabase Auth) so `supabaseClient` calls carry the JWT. Employee identity (code + face) stays as the app-level gate on top.
5. **Apply BLOCK B** (RLS + policies) in SQL Editor.
6. **Verify** — confirm one company's session cannot read another company's `attendance_logs`/`employees`.

### Interim mitigations until step 5
- Treat the publishable key as semi-public; do **not** ship the `service_role` key in any client.
- Keep the deployment **single-tenant** (one company) — current state — which removes the cross-tenant exposure in practice.

## Final verification status
See the report in chat. Core workflow verified end-to-end with live data (records 49/50/51, audit log, worked-hours fix). Live multi-device face-and-GPS pass should be repeated on the release APK before go-live.
