# twitter_clone

Twitter clone build with Flutter and Supabase.

```sql
-- Tables
create table if not exists public.users (
    id uuid primary key not null references auth.users(id),
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    name text not null unique,
    description text not null,
    image_url text,
    constraint username_validation check (char_length(name) >= 1 and char_length(name) <= 24),
    constraint description_validation check (char_length(description) <= 160)
);

create table if not exists public.posts (
    id uuid not null primary key default uuid_generate_v4(),
    user_id uuid references public.users(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    body text not null,
    constraint tweet_length_validation check (char_length(body) <= 280)
);

create table if not exists public.likes (
    id uuid not null primary key default uuid_generate_v4(),
    post_id uuid references public.posts(id) on delete cascade not null,
    user_id uuid references public.users(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    unique (post_id, user_id)
);

-- enum for different types of notifications
create type notification_type as enum ('like');

create table if not exists public.notifications (
    id uuid not null primary key default uuid_generate_v4(),
    type notification_type not null,

    -- the user who will receive the notification
    notifier_id uuid references public.users(id) on delete cascade not null,

    -- the user who performed the action
    actor_id uuid references public.users(id) on delete set null,

    -- id of the entity of the action. e.g. likes.id for `like` type
    entity_id uuid,

    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    unique (type, notifier_id, actor_id, entity_id)
);

--  Row Level Policy
alter table public.users enable row level security;
create policy "Public profiles are viewable by everyone." on public.users for select using (true);
create policy "Can insert user" on public.users for insert with check (auth.uid() = id);
create policy "Can update user" on public.users for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "Can delete user" on public.users for delete using (auth.uid() = id);

alter table public.posts enable row level security;
create policy "Posts are viewable by everyone. " on public.posts for select using (true);
create policy "Can insert posts" on public.posts for insert with check (auth.uid() = user_id);
create policy "Can update posts" on public.posts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Can delete posts" on public.posts for delete using (auth.uid() = user_id);

alter table public.likes enable row level security;
create policy "Likes are viewable by everyone. " on public.likes for select using (true);
create policy "Users can insert their own likes." on public.likes for insert with check (auth.uid() = user_id);
create policy "Users can delete own likes." on public.likes for delete using (auth.uid() = user_id);

alter table public.notifications enable row level security;
create policy "Notifications are viewable by the user" on public.notifications for select using (auth.uid() = notifier_id);

-- Views
create or replace view notifications_view
    with (security_invoker = on) as
        select 
            n.type,
            n.entity_id,
            n.actor_id,
            n.created_at,
            case 
                when n.type = 'like' then
                    (select jsonb_build_object(
                        'actor', jsonb_build_object(
                            'name', u.name,
                            'image_url', u.image_url
                        ),
                        'post', jsonb_build_object(
                            'body', p.body,
                            'id', p.id
                        )
                    )
                    from public.likes l
                    inner join public.users u
                        on l.user_id = u.id
                    inner join public.posts p
                        on l.post_id = p.id
                    where n.entity_id = l.id)
                else null
            end as metadata
        from public.notifications n
        order by n.created_at desc;
```