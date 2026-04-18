-- Create extension for UUID and crypto if not exists
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- 1. AUTH & PROFILES
-- ==========================================
-- Note: In Supabase, auth.users is handled by the GoTrue service. 
-- For local development with the Supabase CLI, you can insert directly into auth.users.
INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, instance_id)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'renee@example.com', crypt('password123', gen_salt('bf')), now(), now(), now(), '', '', '', '00000000-0000-0000-0000-000000000000'),
  ('a0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'alex@example.com', crypt('password123', gen_salt('bf')), now(), now(), now(), '', '', '', '00000000-0000-0000-0000-000000000000'),
  ('a0000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'sam@example.com', crypt('password123', gen_salt('bf')), now(), now(), now(), '', '', '', '00000000-0000-0000-0000-000000000000')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, student_name, avatar_url)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Renee', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Renee'),
  ('a0000000-0000-0000-0000-000000000002', 'Alex', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Alex'),
  ('a0000000-0000-0000-0000-000000000003', 'Sam', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Sam')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 2. TIMETABLE ENTRIES (Renee - Engineering)
-- ==========================================
INSERT INTO public.timetable_entries (user_id, day, subject, start_time, room, duration_minutes)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Monday', 'Operating Systems', '09:00 AM', 'Room 301', 90),
  ('a0000000-0000-0000-0000-000000000001', 'Monday', 'OS Lab', '11:00 AM', 'Lab 4', 120),
  ('a0000000-0000-0000-0000-000000000001', 'Tuesday', 'Data Structures', '10:00 AM', 'Room 205', 90),
  ('a0000000-0000-0000-0000-000000000001', 'Tuesday', 'Database Systems', '01:00 PM', 'Room 102', 90),
  ('a0000000-0000-0000-0000-000000000001', 'Wednesday', 'Computer Networks', '09:00 AM', 'Room 401', 90),
  ('a0000000-0000-0000-0000-000000000001', 'Wednesday', 'Software Engineering', '11:30 AM', 'Room 202', 90),
  ('a0000000-0000-0000-0000-000000000001', 'Thursday', 'Operating Systems', '10:00 AM', 'Room 301', 90),
  ('a0000000-0000-0000-0000-000000000001', 'Friday', 'Data Structures', '09:00 AM', 'Room 205', 90),
  ('a0000000-0000-0000-0000-000000000001', 'Friday', 'Networks Lab', '02:00 PM', 'Lab 2', 120);

-- ==========================================
-- 3. ATTENDANCE (Hovering around 75%)
-- ==========================================
INSERT INTO public.attendance (user_id, subject, attended_count, total_count, target_percentage)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Operating Systems', 15, 20, 75.0),    -- 75%
  ('a0000000-0000-0000-0000-000000000001', 'OS Lab', 11, 14, 75.0),             -- 78.5%
  ('a0000000-0000-0000-0000-000000000001', 'Data Structures', 14, 19, 75.0),    -- 73.6%
  ('a0000000-0000-0000-0000-000000000001', 'Database Systems', 12, 16, 75.0),   -- 75%
  ('a0000000-0000-0000-0000-000000000001', 'Computer Networks', 16, 21, 75.0),  -- 76.1%
  ('a0000000-0000-0000-0000-000000000001', 'Software Engineering', 13, 18, 75.0);-- 72.2%

-- ==========================================
-- 4. KANBAN TASKS (15 Tasks)
-- ==========================================
INSERT INTO public.kanban_tasks (user_id, title, description, assignee, status, due_date)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Prepare for OS Lab Viva', 'Review page replacement algorithms and deadlocks', 'Renee', 'todo', now() + interval '2 days'),
  ('a0000000-0000-0000-0000-000000000001', 'Complete DB Normalization Assignment', '1NF to BCNF for hospital management schema', 'Renee', 'doing', now() + interval '1 day'),
  ('a0000000-0000-0000-0000-000000000001', 'Read Chapter 4 of Networks', 'Subnetting and routing protocols', 'Renee', 'done', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000001', 'Write Software Engineering PRD', 'Draft requirements for the new project module', 'Renee', 'todo', now() + interval '5 days'),
  ('a0000000-0000-0000-0000-000000000001', 'Practice Graph Algorithms', 'Dijkstra and A* implementations', 'Renee', 'doing', now() + interval '3 days'),
  ('a0000000-0000-0000-0000-000000000001', 'Submit OS Assignment 2', 'Process scheduling simulation code', 'Renee', 'done', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000001', 'Buy notebooks and pens', 'Need stationary for the semester', 'Renee', 'todo', null),
  ('a0000000-0000-0000-0000-000000000002', 'Research Cloud Providers', 'Compare AWS and GCP for final year project', 'Alex', 'doing', now() + interval '2 days'),
  ('a0000000-0000-0000-0000-000000000002', 'Setup Docker Container', 'For the database local environment', 'Alex', 'done', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000002', 'Write API Endpoints', 'Implement CRUD for users', 'Alex', 'todo', now() + interval '4 days'),
  ('a0000000-0000-0000-0000-000000000002', 'Fix Auth Bug', 'JWT token expiration issue', 'Alex', 'doing', now() + interval '1 day'),
  ('a0000000-0000-0000-0000-000000000003', 'Design UI Mockups', 'Figma screens for Lumina Dashboard', 'Sam', 'done', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000003', 'Create Logo Vector', 'Export in SVG and PNG', 'Sam', 'todo', now() + interval '2 days'),
  ('a0000000-0000-0000-0000-000000000003', 'Usability Testing', 'Test the new navigation flow', 'Sam', 'doing', now() + interval '4 days'),
  ('a0000000-0000-0000-0000-000000000003', 'Update Color Palette', 'Adjust contrast for accessibility', 'Sam', 'done', now() - interval '1 day');

-- ==========================================
-- 5. FOCUS SESSIONS (10 Sessions)
-- ==========================================
INSERT INTO public.focus_sessions (user_id, label, start_time, end_time, app_switches, distractions)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'OS Revision', now() - interval '2 days 4 hours', now() - interval '2 days 3 hours', 2, 1),
  ('a0000000-0000-0000-0000-000000000001', 'DB Assignment', now() - interval '2 days 1 hour', now() - interval '2 days', 8, 4),
  ('a0000000-0000-0000-0000-000000000001', 'Deep Work: Coding', now() - interval '1 day 5 hours', now() - interval '1 day 3 hours', 1, 0),
  ('a0000000-0000-0000-0000-000000000001', 'Graph Algo Practice', now() - interval '1 day 2 hours', now() - interval '1 day 1 hour', 5, 2),
  ('a0000000-0000-0000-0000-000000000001', 'Networks Reading', now() - interval '10 hours', now() - interval '9 hours', 12, 6),
  ('a0000000-0000-0000-0000-000000000002', 'API Integration', now() - interval '2 days', now() - interval '2 days - 45 minutes', 4, 1),
  ('a0000000-0000-0000-0000-000000000002', 'Docker Debugging', now() - interval '1 day', now() - interval '1 day - 120 minutes', 15, 8),
  ('a0000000-0000-0000-0000-000000000002', 'Cloud Research', now() - interval '5 hours', now() - interval '4 hours', 6, 3),
  ('a0000000-0000-0000-0000-000000000003', 'Figma Designing', now() - interval '3 days', now() - interval '3 days - 90 minutes', 3, 1),
  ('a0000000-0000-0000-0000-000000000003', 'Prototyping', now() - interval '1 day', now() - interval '1 day - 60 minutes', 7, 2);

-- ==========================================
-- 6. STUDY ROOMS & HUB MESSAGES
-- ==========================================
INSERT INTO public.study_rooms (id, owner_id, name, code)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'OS Survival Group', 'OS-SURV'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'FYP Sync', 'FYP-2026')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.room_members (room_id, user_id, role)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'admin'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'editor'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'viewer'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'admin'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'editor'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'editor')
ON CONFLICT (room_id, user_id) DO NOTHING;

INSERT INTO public.hub_messages (room_id, sender_id, content, type, created_at)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Guys, the OS Lab Viva is tomorrow. Who is ready?', 'text', now() - interval '20 hours'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'I am definitely not ready. Prof said he will ask about Semaphores.', 'text', now() - interval '19 hours 55 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Wait, really? I thought it was just scheduling algorithms!', 'text', now() - interval '19 hours 50 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'No, he sent an email last night. It covers deadlocks and synchronization too.', 'text', now() - interval '19 hours 45 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'GG. Im going to fail.', 'text', now() - interval '19 hours 40 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Does anyone have good notes on the Dining Philosophers problem?', 'text', now() - interval '19 hours 30 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Yeah, I found a great YouTube video explaining it. Let me pin it.', 'text', now() - interval '19 hours 25 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Pinned a link.', 'system', now() - interval '19 hours 24 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Lifesaver! What about Banker''s Algorithm?', 'text', now() - interval '19 hours 10 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Banker''s is easy, just matrix subtraction. Need to find the safe sequence.', 'text', now() - interval '19 hours'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Are we expected to write code on paper or just explain the logic?', 'text', now() - interval '18 hours 50 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Mostly logic and tracing for the Viva, but maybe pseudo-code.', 'text', now() - interval '18 hours 40 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Alright, I''m logging off to grind. See you guys in the lab.', 'text', now() - interval '18 hours 30 minutes'),
  ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', 'Good luck. We''ll need it.', 'text', now() - interval '18 hours 20 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Hey, just checking in. Did anyone figure out the Mutex implementation in C?', 'text', now() - interval '10 hours'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Use pthread_mutex_t. Don''t overcomplicate it.', 'text', now() - interval '9 hours 50 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Yeah, remember to init and destroy the mutex.', 'text', now() - interval '9 hours 40 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Got it, thanks. Just ran my simulation, no deadlocks!', 'text', now() - interval '9 hours 30 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Nice! Wish me luck on mine.', 'text', now() - interval '9 hours 20 minutes'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'We got this guys. Sleep well!', 'text', now() - interval '9 hours');

-- ==========================================
-- 7. TRANSACTIONS (30 Transactions)
-- ==========================================
INSERT INTO public.transactions (user_id, amount, category, type, tags, people_count, raw_message, date)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 12.50, 'Food', 'spent', ARRAY['lunch', 'cafeteria'], 1, 'Bought lunch at the student cafeteria', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000001', 5.00, 'Travel', 'spent', ARRAY['bus', 'commute'], 1, 'Bus fare to campus', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000001', 45.00, 'Food', 'split', ARRAY['dinner', 'group'], 3, 'Dinner with Alex and Sam at pizza place', now() - interval '4 days'),
  ('a0000000-0000-0000-0000-000000000001', 15.00, 'Food', 'received', ARRAY['split', 'venmo'], 1, 'Alex paid back for pizza', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000001', 15.00, 'Food', 'received', ARRAY['split', 'venmo'], 1, 'Sam paid back for pizza', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000001', 8.50, 'Stationery', 'spent', ARRAY['notebook', 'pens'], 1, 'Bought supplies for the semester', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000001', 4.00, 'Food', 'spent', ARRAY['coffee'], 1, 'Morning coffee before OS Lab', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000001', 10.00, 'Travel', 'spent', ARRAY['uber', 'late'], 1, 'Uber home because I stayed late in the lab', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000001', 14.00, 'Food', 'spent', ARRAY['lunch'], 1, 'Burrito bowl', now() - interval '12 hours'),
  ('a0000000-0000-0000-0000-000000000001', 6.00, 'Food', 'spent', ARRAY['snacks'], 1, 'Vending machine snacks', now() - interval '2 hours'),
  
  ('a0000000-0000-0000-0000-000000000002', 15.00, 'Food', 'spent', ARRAY['dinner', 'split'], 1, 'Sent to Renee for pizza', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000002', 20.00, 'Subscriptions', 'spent', ARRAY['software', 'docker'], 1, 'Cloud credits', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000002', 7.50, 'Food', 'spent', ARRAY['breakfast'], 1, 'Bagel and coffee', now() - interval '4 days'),
  ('a0000000-0000-0000-0000-000000000002', 30.00, 'Travel', 'split', ARRAY['cab', 'weekend'], 2, 'Cab ride with Sam', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000002', 15.00, 'Travel', 'received', ARRAY['split'], 1, 'Sam paid half for cab', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000002', 11.00, 'Food', 'spent', ARRAY['lunch'], 1, 'Sandwich shop', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000002', 3.50, 'Food', 'spent', ARRAY['snack'], 1, 'Chips', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000002', 9.00, 'Food', 'spent', ARRAY['dinner'], 1, 'Fast food', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000002', 50.00, 'Books', 'spent', ARRAY['textbook'], 1, 'Used OS Textbook', now() - interval '10 hours'),
  ('a0000000-0000-0000-0000-000000000002', 4.50, 'Food', 'spent', ARRAY['coffee'], 1, 'Energy drink', now() - interval '1 hour'),

  ('a0000000-0000-0000-0000-000000000003', 15.00, 'Food', 'spent', ARRAY['dinner', 'split'], 1, 'Sent to Renee for pizza', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000003', 15.00, 'Travel', 'spent', ARRAY['cab', 'split'], 1, 'Paid Alex for cab', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000003', 18.00, 'Subscriptions', 'spent', ARRAY['figma', 'design'], 1, 'Design software sub', now() - interval '6 days'),
  ('a0000000-0000-0000-0000-000000000003', 5.50, 'Food', 'spent', ARRAY['coffee'], 1, 'Latte', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000003', 12.00, 'Food', 'spent', ARRAY['lunch'], 1, 'Salad bar', now() - interval '4 days'),
  ('a0000000-0000-0000-0000-000000000003', 25.00, 'Shopping', 'spent', ARRAY['clothes'], 1, 'New t-shirt', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000003', 8.00, 'Food', 'spent', ARRAY['breakfast'], 1, 'Pancakes', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000003', 22.00, 'Entertainment', 'spent', ARRAY['movies'], 1, 'Movie ticket', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000003', 6.50, 'Food', 'spent', ARRAY['snacks'], 1, 'Popcorn at movies', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000003', 14.50, 'Food', 'spent', ARRAY['dinner'], 1, 'Thai food delivery', now() - interval '5 hours');
