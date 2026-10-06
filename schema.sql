-- PrimeFit Launch Command Center — shared realtime backend
-- Workspace-scoped schema for the primefit-launch Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.primefit_workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);
insert into public.primefit_workspaces (id,name)
values ('11111111-1111-4111-8111-111111111111','PrimeFit Launch')
on conflict (id) do nothing;

create table if not exists public.primefit_members (
  workspace_id uuid not null references public.primefit_workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check(role in ('owner','member')),
  created_at timestamptz not null default now(),
  primary key (workspace_id,user_id)
);
create table if not exists public.primefit_task_progress (
  workspace_id uuid not null references public.primefit_workspaces(id) on delete cascade,
  task_key text not null,
  completed boolean not null default true,
  completed_by uuid references auth.users(id) on delete set null,
  completed_by_email text,
  completed_at timestamptz not null default now(),
  primary key (workspace_id,task_key)
);
create table if not exists public.primefit_notes (
  workspace_id uuid primary key references public.primefit_workspaces(id) on delete cascade,
  notes text not null default '',
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);
insert into public.primefit_notes(workspace_id,notes)
values ('11111111-1111-4111-8111-111111111111','')
on conflict (workspace_id) do nothing;

create index if not exists primefit_members_user_idx on public.primefit_members(user_id);
create index if not exists primefit_notes_updated_by_idx on public.primefit_notes(updated_by);

alter table public.primefit_workspaces enable row level security;
alter table public.primefit_members enable row level security;
alter table public.primefit_task_progress enable row level security;
alter table public.primefit_notes enable row level security;

revoke all on public.primefit_workspaces from anon;
revoke all on public.primefit_members from anon;
revoke all on public.primefit_task_progress from anon;
revoke all on public.primefit_notes from anon;
grant select on public.primefit_workspaces to authenticated;
grant select,insert on public.primefit_members to authenticated;
grant select,insert,update,delete on public.primefit_task_progress to authenticated;
grant select,insert,update,delete on public.primefit_notes to authenticated;

drop policy if exists "primefit workspace members can read workspace" on public.primefit_workspaces;
create policy "primefit workspace members can read workspace" on public.primefit_workspaces
for select to authenticated using (exists (select 1 from public.primefit_members m where m.workspace_id=id and m.user_id=(select auth.uid())));

drop policy if exists "primefit users can read own membership" on public.primefit_members;
create policy "primefit users can read own membership" on public.primefit_members
for select to authenticated using (user_id=(select auth.uid()));

drop policy if exists "primefit users can join launch workspace" on public.primefit_members;
create policy "primefit users can join launch workspace" on public.primefit_members
for insert to authenticated
with check (user_id=(select auth.uid()) and workspace_id='11111111-1111-4111-8111-111111111111'::uuid and role='member');

drop policy if exists "primefit members read task progress" on public.primefit_task_progress;
create policy "primefit members read task progress" on public.primefit_task_progress
for select to authenticated using (exists (select 1 from public.primefit_members m where m.workspace_id=primefit_task_progress.workspace_id and m.user_id=(select auth.uid())));

drop policy if exists "primefit members insert task progress" on public.primefit_task_progress;
create policy "primefit members insert task progress" on public.primefit_task_progress
for insert to authenticated
with check (completed_by=(select auth.uid()) and exists (select 1 from public.primefit_members m where m.workspace_id=primefit_task_progress.workspace_id and m.user_id=(select auth.uid())));

drop policy if exists "primefit members update task progress" on public.primefit_task_progress;
create policy "primefit members update task progress" on public.primefit_task_progress
for update to authenticated
using (exists (select 1 from public.primefit_members m where m.workspace_id=primefit_task_progress.workspace_id and m.user_id=(select auth.uid())))
with check (completed_by=(select auth.uid()) and exists (select 1 from public.primefit_members m where m.workspace_id=primefit_task_progress.workspace_id and m.user_id=(select auth.uid())));

drop policy if exists "primefit members delete task progress" on public.primefit_task_progress;
create policy "primefit members delete task progress" on public.primefit_task_progress
for delete to authenticated using (exists (select 1 from public.primefit_members m where m.workspace_id=primefit_task_progress.workspace_id and m.user_id=(select auth.uid())));

drop policy if exists "primefit members read notes" on public.primefit_notes;
create policy "primefit members read notes" on public.primefit_notes
for select to authenticated using (exists (select 1 from public.primefit_members m where m.workspace_id=primefit_notes.workspace_id and m.user_id=(select auth.uid())));

drop policy if exists "primefit members insert notes" on public.primefit_notes;
create policy "primefit members insert notes" on public.primefit_notes
for insert to authenticated
with check (updated_by=(select auth.uid()) and exists (select 1 from public.primefit_members m where m.workspace_id=primefit_notes.workspace_id and m.user_id=(select auth.uid())));

drop policy if exists "primefit members update notes" on public.primefit_notes;
create policy "primefit members update notes" on public.primefit_notes
for update to authenticated
using (exists (select 1 from public.primefit_members m where m.workspace_id=primefit_notes.workspace_id and m.user_id=(select auth.uid())))
with check (updated_by=(select auth.uid()) and exists (select 1 from public.primefit_members m where m.workspace_id=primefit_notes.workspace_id and m.user_id=(select auth.uid())));

do $$ begin
  alter publication supabase_realtime add table public.primefit_task_progress;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.primefit_notes;
exception when duplicate_object then null; end $$;

-- The app auto-adds signed-in users to the launch workspace as members.
