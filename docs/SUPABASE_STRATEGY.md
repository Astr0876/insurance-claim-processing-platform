# Supabase Integration Strategy - LUMINA

This document outlines the schema design and migration plan for connecting the LUMINA Flutter app to Supabase.

## 1. Schema Design (SQL)

Run the following SQL in your Supabase SQL Editor to create the required tables.

```sql
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

-- Create Policies (Example: Users can only see their own data)
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
-- Repeat for other tables...
```

## 2. Implementation Steps

1.  **Authentication**: Implement a Sign-In/Sign-Up flow using Supabase Auth.
2.  **Service Refactoring**: 
    *   Modify `TimetableService` to fetch from `timetable_entries`.
    *   Modify `AttendanceService` to sync with `attendance` table.
    *   Modify `KanbanService` to use `kanban_tasks`.
    *   Modify `HubService` to use Realtime for messages and presence.
3.  **Realtime Integration**: Enable Realtime on `hub_messages` and `study_rooms` for collaborative features.

## 3. Current Progress

- ✅ `supabase_flutter` dependency added.
- ✅ Supabase initialized in `main.dart`.
- ✅ Supabase credentials added to `AppConstants`.
- ✅ Database Schema drafted.

## 4. Next Actions

- I am waiting for you to execute the SQL in your Supabase dashboard.
- Once the tables are created, I can start refactoring the services to use Supabase instead of demo data.
