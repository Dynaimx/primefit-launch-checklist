-- PrimeFit Launch Command Center — shared realtime backend
create table if not exists public.primefit_task_progress (
  task_key text primary key,
  completed boolean not null default true,
  completed_by uuid references auth.users(id) on delete set null,
  completed_by_email text,
  completed_at timestamptz not null default now()
);
create table if not exists public.primefit_notes (
  id integer primary key check (id = 1),
  notes text not null default '',
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);
insert into public.primefit_notes (id, notes) values (1, '') on conflict (id) do nothing;
alter table public.primefit_task_progress enable row level security;
alter table public.primefit_notes enable row level security;
drop policy if exists "authenticated users can read task progress" on public.primefit_task_progress;
create policy "authenticated users can read task progress" on public.primefit_task_progress for select to authenticated using (true);
drop policy if exists "authenticated users can insert task progress" on public.primefit_task_progress;
create policy "authenticated users can insert task progress" on public.primefit_task_progress for insert to authenticated with check (true);
drop policy if exists "authenticated users can update task progress" on public.primefit_task_progress;
create policy "authenticated users can update task progress" on public.primefit_task_progress for update to authenticated using (true) with check (true);
drop policy if exists "authenticated users can delete task progress" on public.primefit_task_progress;
create policy "authenticated users can delete task progress" on public.primefit_task_progress for delete to authenticated using (true);
drop policy if exists "authenticated users can read notes" on public.primefit_notes;
create policy "authenticated users can read notes" on public.primefit_notes for select to authenticated using (true);
drop policy if exists "authenticated users can insert notes" on public.primefit_notes;
create policy "authenticated users can insert notes" on public.primefit_notes for insert to authenticated with check (true);
drop policy if exists "authenticated users can update notes" on public.primefit_notes;
create policy "authenticated users can update notes" on public.primefit_notes for update to authenticated using (true) with check (true);
drop policy if exists "authenticated users can delete notes" on public.primefit_notes;
create policy "authenticated users can delete notes" on public.primefit_notes for delete to authenticated using (true);
alter publication supabase_realtime add table public.primefit_task_progress;
alter publication supabase_realtime add table public.primefit_notes;