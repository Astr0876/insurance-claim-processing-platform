-- 1. Profiles (linked to auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  student_name text,
  avatar_url text,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Timetable Entries
create table public.timetable_entries (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  day text not null, -- Monday, Tuesday, etc.
  subject text not null,
  start_time text not null, -- 09:00 AM
  room text,
  duration_minutes integer default 60,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Attendance Records
create table public.attendance (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  subject text not null,
  attended_count integer default 0,
  total_count integer default 0,
  unique(user_id, subject)
);

-- 4. Kanban Tasks
create table public.kanban_tasks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  title text not null,
  description text,
  assignee text,
  assignee_avatar text,
  status text check (status in ('todo', 'doing', 'done')) default 'todo',
  due_date timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Focus Sessions
create table public.focus_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  label text,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  app_switches integer default 0,
  distractions integer default 0
);

-- 6. Study Rooms (Collaborative)
create table public.study_rooms (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid references auth.users not null,
  name text not null,
  code text unique not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. Room Members
create table public.room_members (
  room_id uuid references public.study_rooms on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  role text check (role in ('admin', 'editor', 'viewer')) default 'viewer',
  joined_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (room_id, user_id)
);

-- 8. Hub Messages
create table public.hub_messages (
  id uuid default gen_random_uuid() primary key,
  room_id uuid references public.study_rooms on delete cascade not null,
  sender_id uuid references auth.users not null,
  content text not null,
  type text check (type in ('text', 'system', 'file')) default 'text',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 9. Expenses / Transactions
create table public.transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  amount decimal not null,
  category text,
  type text check (type in ('spent', 'received', 'split')) default 'spent',
  tags text[],
  people_count integer default 1,
  raw_message text,
  date timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS) on all tables
alter table public.profiles enable row level security;
alter table public.timetable_entries enable row level security;
alter table public.attendance enable row level security;
alter table public.kanban_tasks enable row level security;
alter table public.focus_sessions enable row level security;
alter table public.study_rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.hub_messages enable row level security;
alter table public.transactions enable row level security;

-- Create Policies
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

create policy "Users can view own timetable" on public.timetable_entries for select using (auth.uid() = user_id);
create policy "Users can insert own timetable" on public.timetable_entries for insert with check (auth.uid() = user_id);
create policy "Users can update own timetable" on public.timetable_entries for update using (auth.uid() = user_id);
create policy "Users can delete own timetable" on public.timetable_entries for delete using (auth.uid() = user_id);

create policy "Users can view own attendance" on public.attendance for select using (auth.uid() = user_id);
create policy "Users can manage own attendance" on public.attendance for all using (auth.uid() = user_id);

create policy "Users can manage own tasks" on public.kanban_tasks for all using (auth.uid() = user_id);

create policy "Users can manage own sessions" on public.focus_sessions for all using (auth.uid() = user_id);

create policy "Users can view study rooms they belong to" on public.study_rooms 
  for select using (
    exists (
      select 1 from public.room_members 
      where room_id = public.study_rooms.id and user_id = auth.uid()
    )
  );

create policy "Users can manage messages in their rooms" on public.hub_messages
  for all using (
    exists (
      select 1 from public.room_members 
      where room_id = public.hub_messages.room_id and user_id = auth.uid()
    )
  );

create policy "Users can manage own transactions" on public.transactions for all using (auth.uid() = user_id);
