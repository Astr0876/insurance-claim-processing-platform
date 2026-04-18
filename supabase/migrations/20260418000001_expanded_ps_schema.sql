-- Expanded Schema for LUMINA: The Proactive Engineering Sidekick

-- 1. Attendance Logs (Historical tracking for Bunk Analytics)
create table public.attendance_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  subject text not null,
  class_date date not null default current_date,
  status text check (status in ('attended', 'absent')) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. ContextSwitch: Detailed App Usage Events
create table public.app_usage_events (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  app_name text not null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone,
  is_study_app boolean default false,
  cognitive_penalty decimal default 0.0
);

-- 3. Daily Metrics (Cognitive Debt, Focus Score, Stress Level for Heatmap)
create table public.daily_metrics (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  metric_date date not null default current_date,
  cognitive_debt_score decimal default 0.0,
  focus_score decimal default 0.0,
  stress_level_score decimal default 0.0,
  study_minutes integer default 0,
  unique(user_id, metric_date)
);

-- 4. External Deadlines (Extracted from Gmail/Calendar scans)
create table public.external_deadlines (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  source text check (source in ('gmail', 'calendar')) not null,
  title text not null,
  deadline_at timestamp with time zone not null,
  priority_score integer default 1, -- 1-5
  raw_metadata jsonb, -- Stores email snippets or keywords
  is_completed boolean default false
);

-- 5. Discussion Hub: Pinned Items (Pasteboard/Snippets/Logic Gates)
create table public.pinned_items (
  id uuid default gen_random_uuid() primary key,
  room_id uuid references public.study_rooms on delete cascade not null,
  user_id uuid references auth.users on delete set null,
  item_type text check (item_type in ('code_snippet', 'image_logic', 'text_note')) not null,
  content text not null,
  label text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Discussion Hub: Whiteboard Data (JSON Snapshots)
create table public.whiteboard_data (
  id uuid references public.study_rooms on delete cascade primary key,
  shapes_json jsonb not null default '[]'::jsonb,
  last_modified_by uuid references auth.users on delete set null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. LaTeX Integration (Overleaf/Remote Preview)
create table public.latex_projects (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  room_id uuid references public.study_rooms on delete cascade, -- Optional: shared lab reports
  project_name text not null,
  overleaf_url text,
  preview_url text, -- Latest compiled PDF/Image link
  last_compiled_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 8. Activity Logs (Team Progress Engine Feed)
create table public.activity_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  room_id uuid references public.study_rooms on delete cascade,
  action_type text not null, -- e.g., 'task_moved', 'message_sent', 'bunk_recorded'
  description text,
  metadata jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.attendance_logs enable row level security;
alter table public.app_usage_events enable row level security;
alter table public.daily_metrics enable row level security;
alter table public.external_deadlines enable row level security;
alter table public.pinned_items enable row level security;
alter table public.whiteboard_data enable row level security;
alter table public.latex_projects enable row level security;
alter table public.activity_logs enable row level security;

-- Policies
create policy "Users can manage own attendance logs" on public.attendance_logs for all using (auth.uid() = user_id);
create policy "Users can manage own app usage" on public.app_usage_events for all using (auth.uid() = user_id);
create policy "Users can manage own metrics" on public.daily_metrics for all using (auth.uid() = user_id);
create policy "Users can manage own external deadlines" on public.external_deadlines for all using (auth.uid() = user_id);
create policy "Room members can manage pinned items" on public.pinned_items
  for all using (exists (select 1 from public.room_members where room_id = public.pinned_items.room_id and user_id = auth.uid()));
create policy "Room members can manage whiteboard" on public.whiteboard_data
  for all using (exists (select 1 from public.room_members where room_id = public.whiteboard_data.id and user_id = auth.uid()));
create policy "Users can manage own latex projects" on public.latex_projects for all using (auth.uid() = user_id);
create policy "Room activity is visible to members" on public.activity_logs
  for select using (exists (select 1 from public.room_members where room_id = public.activity_logs.room_id and user_id = auth.uid()));
