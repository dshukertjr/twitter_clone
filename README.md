# twitter_clone

Twitter clone build with Flutter and Supabase.

```sql
-- Tables
create table if not exists public.profiles (
    id uuid primary key not null references auth.users(id),
    name text not null unique,
    description text,
    image_path text,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    constraint username_validation check (char_length(name) >= 1 and char_length(name) <= 24),
    constraint description_validation check (char_length(description) <= 160)
);

create table if not exists public.posts (
    id uuid not null primary key default uuid_generate_v4(),
    user_id uuid references public.profiles(id) on delete cascade not null default auth.uid(),
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    body text not null,
    image_path text,
    constraint tweet_length_validation check (char_length(body) <= 280)
);

create table if not exists public.likes (
    id uuid not null primary key default uuid_generate_v4(),
    post_id uuid references public.posts(id) on delete cascade not null,
    user_id uuid references public.profiles(id) on delete cascade not null default auth.uid(),
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    unique (post_id, user_id)
);

create table if not exists public.rooms (
    id uuid not null primary key default uuid_generate_v4(),
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.rooms is 'Holds chat rooms';

create table if not exists public.messages (
    id uuid not null primary key default uuid_generate_v4(),
    user_id uuid default auth.uid() references public.profiles(id) on delete cascade not null,
    room_id uuid references public.rooms(id) on delete cascade not null,
    content text not null,
    has_been_read boolean default false not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);

create table if not exists public.room_participants (
    id uuid not null primary key default uuid_generate_v4(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    room_id uuid references public.rooms(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    unique (user_id, room_id)
);
comment on table public.room_participants is 'Relational table of users and rooms.';

-- enum for different types of notifications
create type notification_type as enum ('like');

create table if not exists public.notifications (
    id uuid not null primary key default uuid_generate_v4(),
    type notification_type not null,

    -- the user who will receive the notification
    notifier_id uuid references public.profiles(id) on delete cascade not null,

    -- the user who performed the action
    actor_id uuid references public.profiles(id) on delete set null,

    -- id of the entity of the action. e.g. likes.id for `like` type
    entity_id uuid,

    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,

    has_been_read boolean default false not null,
    unique (type, notifier_id, actor_id, entity_id)
);

-- Views
create or replace view notifications_view
    with (security_invoker = on) as
        select 
            n.type,
            n.entity_id,
            n.actor_id,
            n.created_at,
            n.has_been_read,
            case 
                when n.type = 'like' then
                    (select jsonb_build_object(
                        'actor', jsonb_build_object(
                            'id', u.id,
                            'name', u.name,
                            'image_url', u.image_url
                        ),
                        'post', jsonb_build_object(
                            'body', p.body,
                            'id', p.id
                        )
                    )
                    from public.likes l
                    inner join public.profiles u
                        on l.user_id = u.id
                    inner join public.posts p
                        on l.post_id = p.id
                    where n.entity_id = l.post_id
                        and n.actor_id = l.user_id)
                else null
            end as metadata
        from public.notifications n
        order by n.created_at desc;

-- functions & triggers
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name)
  values (new.id, new.raw_user_meta_data->>'name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.handle_likes()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
   notifier_id uuid; 
begin
    select user_id
    into notifier_id
    from public.posts
    where id = new.post_id
        and user_id != new.user_id;

    if found then
        insert into public.notifications (type, notifier_id, actor_id, entity_id)
        values ('like', notifier_id, new.user_id, new.post_id);
    end if;
    
    return new;

end;
$$;

create trigger on_user_like
  after insert on public.likes
  for each row execute procedure public.handle_likes();

create function public.handle_delete_likes()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
   notifier_id uuid; 
begin
    delete from public.notifications
    where type = 'like' and actor_id = old.user_id and entity_id = old.post_id;
    return null;
end;
$$;

create trigger on_user_delete_like
  after delete on public.likes
  for each row execute procedure public.handle_delete_likes();

create or replace function is_room_participant(room_id uuid)
returns boolean as $$
  select exists(
    select 1
    from room_participants
    where room_id = is_room_participant.room_id and user_id = auth.uid()
  );
$$ language sql security definer;

create or replace function create_new_room(other_user_id uuid) returns uuid as $$
    declare
        new_room_id uuid;
    begin
        -- Check if room with both participants already exist
        with rooms_with_profiles as (
            select room_id, array_agg(user_id) as participants
            from room_participants
            group by room_id               
        )
        select room_id
        into new_room_id
        from rooms_with_profiles
        where create_new_room.other_user_id=any(participants)
        and auth.uid()=any(participants);


        if not found then
            -- Create a new room
            insert into public.rooms default values
            returning id into new_room_id;

            -- Insert the caller user into the new room
            insert into public.room_participants (user_id, room_id)
            values (auth.uid(), new_room_id);

            -- Insert the other_user user into the new room
            insert into public.room_participants (user_id, room_id)
            values (other_user_id, new_room_id);
        end if;

        return new_room_id;
    end
$$ language plpgsql security definer;

-- Enable realtime
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.messages;

--  Row Level Policy
alter table public.profiles enable row level security;
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
create policy "Can insert user" on public.profiles for insert with check (auth.uid() = id);
create policy "Can update user" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

alter table public.posts enable row level security;
create policy "Posts are viewable by everyone. " on public.posts for select using (true);
create policy "Can insert posts" on public.posts for insert with check (auth.uid() = user_id);
create policy "Can delete posts" on public.posts for delete using (auth.uid() = user_id);

alter table public.likes enable row level security;
create policy "Likes are viewable by everyone. " on public.likes for select using (true);
create policy "Users can insert their own likes." on public.likes for insert with check (auth.uid() = user_id);
create policy "Users can delete own likes." on public.likes for delete using (auth.uid() = user_id);

alter table public.notifications enable row level security;
create policy "Notifications are viewable by the user" on public.notifications for select using (auth.uid() = notifier_id);

alter table public.rooms enable row level security;
create policy "Users can view rooms that they have joined" on public.rooms for select using (is_room_participant(id));


alter table public.room_participants enable row level security;
create policy "Participants of the room can view other participants." on public.room_participants for select using (is_room_participant(room_id));


alter table public.messages enable row level security;
create policy "Users can view messages on rooms they are in." on public.messages for select using (is_room_participant(room_id));
create policy "Users can insert messages on rooms they are in." on public.messages for insert with check (is_room_participant(room_id) and user_id = auth.uid());

-- Configure storage
insert into storage.buckets (id, name, public) values ('posts', 'posts', true);
insert into storage.buckets (id, name, public) values ('profiles', 'profiles', true);
create policy "uid has to be the owner for insert" on storage.objects for insert with check (auth.uid() = owner);
create policy "uid has to be the owner for update" on storage.objects for update using (auth.uid() = owner) with check (auth.uid() = owner);
```