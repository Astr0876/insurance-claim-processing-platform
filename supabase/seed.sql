-- =============================================================================
-- LUMINA SEED SCRIPT
-- Highly realistic, interconnected mock data for 3 users
-- Targeted for Engineering Students
-- =============================================================================

BEGIN;

-- 1. Create Demo Users in auth.users
-- Password for all: password123
DO $$
DECLARE
  renee_id uuid := 'a0000000-0000-0000-0000-000000000001';
  alex_id  uuid := 'a0000000-0000-0000-0000-000000000002';
  sam_id   uuid := 'a0000000-0000-0000-0000-000000000003';
BEGIN
  -- Insert Renee
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'renee@example.com') THEN
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
    VALUES (renee_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'renee@example.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"student_name":"Renee"}', now(), now(), '', '', '', '');
  END IF;

  -- Insert Alex
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'alex@example.com') THEN
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
    VALUES (alex_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'alex@example.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"student_name":"Alex"}', now(), now(), '', '', '', '');
  END IF;

  -- Insert Sam
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'sam@example.com') THEN
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
    VALUES (sam_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'sam@example.com', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"student_name":"Sam"}', now(), now(), '', '', '', '');
  END IF;
END $$;

-- 2. Seed public.profiles
INSERT INTO public.profiles (id, student_name, avatar_url)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Renee', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Renee'),
  ('a0000000-0000-0000-0000-000000000002', 'Alex', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Alex'),
  ('a0000000-0000-0000-0000-000000000003', 'Sam', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Sam')
ON CONFLICT (id) DO NOTHING;

-- 3. Seed public.timetable_entries (Renee's Engineering Week)
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

-- 4. Seed public.attendance (Hovering ~75%)
INSERT INTO public.attendance (user_id, subject, attended_count, total_count, target_percentage)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Operating Systems', 15, 20, 75.0),
  ('a0000000-0000-0000-0000-000000000001', 'OS Lab', 11, 14, 75.0),
  ('a0000000-0000-0000-0000-000000000001', 'Data Structures', 14, 19, 75.0),
  ('a0000000-0000-0000-0000-000000000001', 'Database Systems', 12, 16, 75.0),
  ('a0000000-0000-0000-0000-000000000001', 'Computer Networks', 16, 21, 75.0),
  ('a0000000-0000-0000-0000-000000000001', 'Software Engineering', 13, 18, 75.0)
ON CONFLICT (user_id, subject) DO UPDATE SET attended_count = EXCLUDED.attended_count, total_count = EXCLUDED.total_count;

-- 5. Seed public.kanban_tasks (15 Tasks)
INSERT INTO public.kanban_tasks (user_id, title, description, assignee, status, due_date)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Prepare for OS Lab Viva', 'Review semaphores and deadlocks', 'Renee', 'todo', now() + interval '1 day'),
  ('a0000000-0000-0000-0000-000000000001', 'Complete DB Assignment', 'Normalize to 3NF', 'Renee', 'doing', now() + interval '2 days'),
  ('a0000000-0000-0000-0000-000000000001', 'Submit Networks Lab Record', 'Topology diagram included', 'Renee', 'done', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000001', 'Study Graph Algorithms', 'DFS, BFS, and Dijkstra', 'Renee', 'todo', now() + interval '3 days'),
  ('a0000000-0000-0000-0000-000000000001', 'Code Review: HubService', 'Fix Realtime listener bug', 'Renee', 'doing', now()),
  ('a0000000-0000-0000-0000-000000000002', 'Research Cloud Hosting', 'Compare AWS and GCP', 'Alex', 'todo', now() + interval '5 days'),
  ('a0000000-0000-0000-0000-000000000002', 'Write Unit Tests', 'Test AuthScreen logic', 'Alex', 'doing', now() + interval '1 day'),
  ('a0000000-0000-0000-0000-000000000002', 'Fix UI padding in Dashboard', 'Align neubrutalist borders', 'Alex', 'done', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000002', 'Update README', 'Installation instructions', 'Alex', 'todo', now() + interval '10 days'),
  ('a0000000-0000-0000-0000-000000000002', 'Setup CI/CD Pipeline', 'GitHub Actions workflow', 'Alex', 'doing', now() + interval '3 days'),
  ('a0000000-0000-0000-0000-000000000003', 'Design Logo', 'Export in SVG', 'Sam', 'todo', now() + interval '7 days'),
  ('a0000000-0000-0000-0000-000000000003', 'Create Figma Mockups', 'Rooms and Chat screens', 'Sam', 'doing', now() + interval '2 days'),
  ('a0000000-0000-0000-0000-000000000003', 'Choose Color Palette', 'Neubrutalist colors', 'Sam', 'done', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000003', 'Write App Pitch', '500 words summary', 'Sam', 'todo', now() + interval '4 days'),
  ('a0000000-0000-0000-0000-000000000003', 'Usability Testing', 'Gather feedback from classmates', 'Sam', 'doing', now() + interval '6 days');

-- 6. Seed public.focus_sessions (10 Sessions)
INSERT INTO public.focus_sessions (user_id, label, start_time, end_time, app_switches, distractions)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'OS Grinding', now() - interval '3 hours', now() - interval '2 hours', 2, 1),
  ('a0000000-0000-0000-0000-000000000001', 'DB Design', now() - interval '1 day', now() - interval '1 day - 45 minutes', 12, 5),
  ('a0000000-0000-0000-0000-000000000001', 'Deep Work: Coding', now() - interval '5 hours', now() - interval '3 hours', 0, 0),
  ('a0000000-0000-0000-0000-000000000002', 'UI Implementation', now() - interval '2 days', now() - interval '2 days - 90 minutes', 5, 2),
  ('a0000000-0000-0000-0000-000000000002', 'API Debugging', now() - interval '8 hours', now() - interval '7 hours', 15, 8),
  ('a0000000-0000-0000-0000-000000000003', 'Figma Prototyping', now() - interval '4 hours', now() - interval '2 hours', 4, 1),
  ('a0000000-0000-0000-0000-000000000003', 'Brainstorming', now() - interval '1 day', now() - interval '1 day - 60 minutes', 2, 0),
  ('a0000000-0000-0000-0000-000000000001', 'Late Night Revise', now() - interval '12 hours', now() - interval '10 hours', 8, 3),
  ('a0000000-0000-0000-0000-000000000002', 'Refactoring', now() - interval '6 hours', now() - interval '5 hours', 10, 4),
  ('a0000000-0000-0000-0000-000000000003', 'Documentation', now() - interval '2 hours', now() - interval '1 hour', 1, 0);

-- 7. Seed public.study_rooms (2 Rooms)
INSERT INTO public.study_rooms (id, owner_id, name, code)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'OS Survival Squad', 'OS-VIVA-26'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'LUMINA Dev Hub', 'LUM-DEV-01');

-- 8. Seed public.room_members (All 3 in both)
INSERT INTO public.room_members (room_id, user_id, role)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'admin'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'editor'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'viewer'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'admin'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'editor'), -- Note: role update if duplicate handled by unique constraint logic
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'editor'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'editor')
ON CONFLICT (room_id, user_id) DO NOTHING;

-- 9. Seed public.hub_messages (20 Messages about OS Lab Viva)
INSERT INTO public.hub_messages (room_id, sender_id, content, type)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Guys, who finished the OS Lab Viva prep?', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Im stuck on Banker''s Algorithm... the matrix subtraction is killing me.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Banker''s is easy, just focus on the Safe Sequence.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Prof said he might ask about Dining Philosophers too.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'No way. That code is huge.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'I have a snippet that simplifies it. Pinned it to the board.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Shared a code snippet.', 'system'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Thanks Renee!', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Wait, what about Semaphores vs Mutex?', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Semaphore is just a counter, Mutex is a lock. Keep it simple.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Has anyone traced the Deadlock avoidance logic?', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'I did. Its just resource allocation graphs.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Be careful with cycles. Cycle = Deadlock in single resource instances.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Good catch.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'What time is the Viva?', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', '10:00 AM sharp in the main lab.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Im doomed.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Dont worry, we got this. Revision session in 10 mins?', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'In.', 'text'),
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Im joining too. Let me grab my notebook.', 'text');

-- 10. Seed public.transactions (30 Transactions)
INSERT INTO public.transactions (user_id, amount, category, type, tags, people_count, raw_message, date)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 15.00, 'Food', 'spent', ARRAY['lunch', 'cafeteria'], 1, 'Lunch at campus cafeteria', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000001', 5.50, 'Travel', 'spent', ARRAY['bus'], 1, 'Bus fare to uni', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000001', 45.00, 'Food', 'split', ARRAY['dinner', 'pizza'], 3, 'Pizza dinner split with Alex/Sam', now() - interval '4 days'),
  ('a0000000-0000-0000-0000-000000000001', 15.00, 'Food', 'received', ARRAY['reimbursement'], 1, 'Alex paid for pizza', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000001', 15.00, 'Food', 'received', ARRAY['reimbursement'], 1, 'Sam paid for pizza', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000001', 8.20, 'Food', 'spent', ARRAY['coffee'], 1, 'Coffee boost for OS Lab', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000001', 12.00, 'Travel', 'spent', ARRAY['uber'], 1, 'Late night Uber home', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000001', 20.00, 'Shopping', 'spent', ARRAY['books'], 1, 'Used Algorithm textbook', now() - interval '12 hours'),
  ('a0000000-0000-0000-0000-000000000001', 4.50, 'Food', 'spent', ARRAY['snacks'], 1, 'Vending machine', now() - interval '2 hours'),
  ('a0000000-0000-0000-0000-000000000001', 35.00, 'Utilities', 'spent', ARRAY['internet'], 1, 'Monthly broadband', now() - interval '10 days'),
  
  ('a0000000-0000-0000-0000-000000000002', 15.00, 'Food', 'spent', ARRAY['dinner'], 1, 'Paid Renee for pizza', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000002', 12.50, 'Food', 'spent', ARRAY['lunch'], 1, 'Subway on campus', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000002', 6.00, 'Travel', 'spent', ARRAY['metro'], 1, 'Metro ticket', now() - interval '4 days'),
  ('a0000000-0000-0000-0000-000000000002', 10.00, 'Entertainment', 'spent', ARRAY['gaming'], 1, 'Steam sale', now() - interval '6 days'),
  ('a0000000-0000-0000-0000-000000000002', 18.00, 'Food', 'spent', ARRAY['burger'], 1, 'Gourmet burger', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000002', 30.00, 'Travel', 'split', ARRAY['cab', 'weekend'], 2, 'Cab to party split with Sam', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000002', 15.00, 'Travel', 'received', ARRAY['reimbursement'], 1, 'Sam paid for cab', now() - interval '12 hours'),
  ('a0000000-0000-0000-0000-000000000002', 5.50, 'Food', 'spent', ARRAY['snacks'], 1, 'Doritos and soda', now() - interval '8 hours'),
  ('a0000000-0000-0000-0000-000000000002', 25.00, 'Utilities', 'spent', ARRAY['mobile'], 1, 'Phone top-up', now() - interval '15 days'),
  ('a0000000-0000-0000-0000-000000000002', 14.00, 'Food', 'spent', ARRAY['lunch'], 1, 'Taco Bell', now() - interval '1 hour'),

  ('a0000000-0000-0000-0000-000000000003', 15.00, 'Food', 'spent', ARRAY['dinner'], 1, 'Paid Renee for pizza', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000003', 15.00, 'Travel', 'spent', ARRAY['cab'], 1, 'Paid Alex for cab', now() - interval '12 hours'),
  ('a0000000-0000-0000-0000-000000000003', 10.50, 'Food', 'spent', ARRAY['breakfast'], 1, 'Oatmeal and latte', now() - interval '5 days'),
  ('a0000000-0000-0000-0000-000000000003', 22.00, 'Entertainment', 'spent', ARRAY['movies'], 1, 'Avengers ticket', now() - interval '4 days'),
  ('a0000000-0000-0000-0000-000000000003', 7.50, 'Food', 'spent', ARRAY['popcorn'], 1, 'Cinema snacks', now() - interval '4 days'),
  ('a0000000-0000-0000-0000-000000000003', 13.00, 'Food', 'spent', ARRAY['lunch'], 1, 'Salad bowl', now() - interval '3 days'),
  ('a0000000-0000-0000-0000-000000000003', 6.00, 'Travel', 'spent', ARRAY['bus'], 1, 'Bus pass', now() - interval '2 days'),
  ('a0000000-0000-0000-0000-000000000003', 40.00, 'Shopping', 'spent', ARRAY['clothes'], 1, 'New hoodie', now() - interval '1 day'),
  ('a0000000-0000-0000-0000-000000000003', 9.00, 'Food', 'spent', ARRAY['snacks'], 1, 'Late night ramen', now() - interval '5 hours'),
  ('a0000000-0000-0000-0000-000000000003', 11.50, 'Food', 'spent', ARRAY['lunch'], 1, 'Poke bowl', now() - interval '30 minutes');

COMMIT;
