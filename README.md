# PrimeFit Launch Command Center — Realtime Team Version

Shared, realtime version of the PrimeFit launch checklist. GitHub Pages hosts the UI; Supabase provides authentication, shared progress storage and realtime updates.

## Setup

1. Create a Supabase project at https://supabase.com/.
2. Open **SQL Editor** and run `schema.sql`.
3. Enable Email/Password authentication.
4. Create your two PrimeFit team accounts.
5. After both accounts exist, disable public sign-ups so outsiders cannot register.
6. Copy `config.example.js` to `config.js`.
7. Add your Supabase project URL and **anon/public** key to `config.js`.
8. Commit `config.js` to this repo.
9. Open the GitHub Pages site and sign in.

## Existing progress

The app still reads the original `primefit_launch_v1` localStorage key. When you sign in for the first time, it detects completed tasks from your old browser checklist and offers to import them into the shared database.

After import, you and your partner use the same cloud progress. Checkbox changes and Launch Notes sync through Supabase Realtime.

## Security

Never put a Supabase service-role key in the website. Use only the public anon key. Database access is protected by the Row Level Security policies in `schema.sql`.

This version is intentionally simple for a small private team: create the team accounts first, then disable public sign-ups. A future version can add formal invitations, roles and per-task ownership.

## Local fallback

Without Supabase configuration, the checklist still works in local-only mode using browser storage.