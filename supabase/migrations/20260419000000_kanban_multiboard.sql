-- Kanban multi-board schema + legacy task backfill

create table if not exists public.kanban_boards (
  id uuid default gen_random_uuid() primary key,
  owner_id uuid references auth.users on delete cascade not null,
  name text not null,
  visibility text check (visibility in ('private', 'shared')) default 'private' not null,
  is_default boolean default false not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique (owner_id, name)
);

create table if not exists public.kanban_board_members (
  board_id uuid references public.kanban_boards on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null,
  role text check (role in ('owner', 'member')) default 'member' not null,
  joined_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (board_id, user_id)
);

alter table public.kanban_tasks
add column if not exists board_id uuid;

-- create one default personal board for each user who already has tasks
insert into public.kanban_boards (owner_id, name, visibility, is_default)
select distinct t.user_id, 'My Board', 'private', true
from public.kanban_tasks t
where t.user_id is not null
  and not exists (
    select 1
    from public.kanban_boards b
    where b.owner_id = t.user_id
      and b.is_default = true
  );

-- ensure every board has owner membership
insert into public.kanban_board_members (board_id, user_id, role)
select b.id, b.owner_id, 'owner'
from public.kanban_boards b
on conflict (board_id, user_id) do nothing;

-- safely attach legacy tasks to a default board
update public.kanban_tasks t
set board_id = target_board.id
from lateral (
  select b.id
  from public.kanban_boards b
  where b.owner_id = t.user_id
  order by b.is_default desc, b.created_at asc
  limit 1
) as target_board
where t.board_id is null;

-- orphan legacy rows without user_id cannot be mapped to a board safely
delete from public.kanban_tasks
where board_id is null;

alter table public.kanban_tasks
alter column board_id set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'kanban_tasks_board_id_fkey'
  ) then
    alter table public.kanban_tasks
    add constraint kanban_tasks_board_id_fkey
    foreign key (board_id) references public.kanban_boards(id) on delete cascade;
  end if;
end $$;

create index if not exists idx_kanban_tasks_board_id on public.kanban_tasks(board_id);
create index if not exists idx_kanban_tasks_board_status on public.kanban_tasks(board_id, status);
create index if not exists idx_kanban_members_user_id on public.kanban_board_members(user_id);

alter table public.kanban_boards enable row level security;
alter table public.kanban_board_members enable row level security;

-- replace single-user task policy with board-aware access
DROP POLICY IF EXISTS "Users can manage own tasks" ON public.kanban_tasks;
DROP POLICY IF EXISTS "Board members can view boards" ON public.kanban_boards;
DROP POLICY IF EXISTS "Owners can create boards" ON public.kanban_boards;
DROP POLICY IF EXISTS "Owners can update boards" ON public.kanban_boards;
DROP POLICY IF EXISTS "Owners can delete boards" ON public.kanban_boards;
DROP POLICY IF EXISTS "Board membership visible to board members" ON public.kanban_board_members;
DROP POLICY IF EXISTS "Owners can manage board members" ON public.kanban_board_members;
DROP POLICY IF EXISTS "Owners can remove board members" ON public.kanban_board_members;
DROP POLICY IF EXISTS "Board members can view tasks" ON public.kanban_tasks;
DROP POLICY IF EXISTS "Board members can insert tasks" ON public.kanban_tasks;
DROP POLICY IF EXISTS "Board members can update tasks" ON public.kanban_tasks;
DROP POLICY IF EXISTS "Board members can delete tasks" ON public.kanban_tasks;

create policy "Board members can view boards"
on public.kanban_boards for select
using (
  auth.uid() = owner_id
  or exists (
    select 1
    from public.kanban_board_members m
    where m.board_id = public.kanban_boards.id
      and m.user_id = auth.uid()
  )
);

create policy "Owners can create boards"
on public.kanban_boards for insert
with check (auth.uid() = owner_id);

create policy "Owners can update boards"
on public.kanban_boards for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

create policy "Owners can delete boards"
on public.kanban_boards for delete
using (auth.uid() = owner_id);

create policy "Board membership visible to board members"
on public.kanban_board_members for select
using (
  or exists (
    select 1
    from public.kanban_boards b
    where b.id = public.kanban_board_members.board_id
      and (
        b.owner_id = auth.uid()
        or exists (
          select 1
          from public.kanban_board_members m
          where m.board_id = b.id
            and m.user_id = auth.uid()
        )
      )
  )
);

create policy "Owners can manage board members"
on public.kanban_board_members for insert
with check (
  exists (
    select 1
    from public.kanban_boards b
    where b.id = board_id
      and b.owner_id = auth.uid()
  )
);

create policy "Owners can remove board members"
on public.kanban_board_members for delete
using (
  exists (
    select 1
    from public.kanban_boards b
    where b.id = board_id
      and b.owner_id = auth.uid()
  )
);

create policy "Board members can view tasks"
on public.kanban_tasks for select
using (
  exists (
    select 1
    from public.kanban_boards b
    where b.id = board_id
      and (
        b.owner_id = auth.uid()
        or exists (
          select 1
          from public.kanban_board_members m
          where m.board_id = b.id
            and m.user_id = auth.uid()
        )
      )
  )
);

create policy "Board members can insert tasks"
on public.kanban_tasks for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.kanban_boards b
    where b.id = board_id
      and (
        b.owner_id = auth.uid()
        or exists (
          select 1
          from public.kanban_board_members m
          where m.board_id = b.id
            and m.user_id = auth.uid()
        )
      )
  )
);

create policy "Board members can update tasks"
on public.kanban_tasks for update
using (
  exists (
    select 1
    from public.kanban_boards b
    where b.id = board_id
      and (
        b.owner_id = auth.uid()
        or exists (
          select 1
          from public.kanban_board_members m
          where m.board_id = b.id
            and m.user_id = auth.uid()
        )
      )
  )
)
with check (
  exists (
    select 1
    from public.kanban_boards b
    where b.id = board_id
      and (
        b.owner_id = auth.uid()
        or exists (
          select 1
          from public.kanban_board_members m
          where m.board_id = b.id
            and m.user_id = auth.uid()
        )
      )
  )
);

create policy "Board members can delete tasks"
on public.kanban_tasks for delete
using (
  exists (
    select 1
    from public.kanban_boards b
    where b.id = board_id
      and (
        b.owner_id = auth.uid()
        or exists (
          select 1
          from public.kanban_board_members m
          where m.board_id = b.id
            and m.user_id = auth.uid()
        )
      )
  )
);
