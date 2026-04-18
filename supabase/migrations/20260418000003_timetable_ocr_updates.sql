-- Update Attendance table to support OCR-derived Bunk Analytics
alter table public.attendance 
add column if not exists faculty text,
add column if not exists weekly_frequency integer default 1,
add column if not exists monthly_frequency integer default 4,
add column if not exists target_percentage decimal default 75.0;

-- Create a table for the 'Raw' OCR extraction storage (Audit log/History)
create table public.timetable_ocr_extractions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  raw_json jsonb not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.timetable_ocr_extractions enable row level security;

-- Policies
create policy "Users can view own OCR extractions" on public.timetable_ocr_extractions for select using (auth.uid() = user_id);
create policy "Users can insert own OCR extractions" on public.timetable_ocr_extractions for insert with check (auth.uid() = user_id);
