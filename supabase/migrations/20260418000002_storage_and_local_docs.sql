-- Storage Buckets & Local Document Metadata Schema

-- 1. Create Storage Buckets for Shared Assets
-- We only use Supabase Storage for things that MUST be shared (e.g., user avatars, files explicitly shared in the Discussion Hub).
INSERT INTO storage.buckets (id, name, public) 
VALUES 
  ('avatars', 'avatars', true),
  ('hub_files', 'hub_files', false)
ON CONFLICT (id) DO NOTHING;

-- 2. Local Documents Metadata (For RAG & Obsidian-style Graph Mesh)
-- CRITICAL: This table ONLY stores metadata and graph relationships. 
-- The actual file content, notes, and vector embeddings REMAIN STRICTLY ON THE USER'S DEVICE.
create table public.local_documents (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  device_file_id text not null, -- The local path, URI, or ID on the user's device
  title text not null,
  file_type text, -- e.g., 'pdf', 'txt', 'md'
  tags text[],
  
  -- Obsidian-style Graph Mesh Data
  -- Stores relationships (edges to other document IDs) and visual coordinates for the mesh map
  graph_metadata jsonb default '{}'::jsonb, 
  
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, device_file_id)
);

-- Enable RLS
alter table public.local_documents enable row level security;

-- Policies
create policy "Users can manage own local document metadata" on public.local_documents for all using (auth.uid() = user_id);
