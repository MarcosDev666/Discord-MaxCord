-- Run once in a new Supabase project. Tables are protected by RLS.
create extension if not exists pgcrypto;
create table public.profiles (id uuid primary key references auth.users on delete cascade, username text not null check (char_length(username) between 2 and 32));
create table public.servers (id uuid primary key default gen_random_uuid(), name text not null check (char_length(name) between 2 and 60), owner_id uuid not null references auth.users on delete cascade, invite_code text not null unique default encode(gen_random_bytes(8), 'hex'));
create table public.members (server_id uuid references public.servers on delete cascade, user_id uuid references auth.users on delete cascade, role text not null default 'member' check (role in ('owner','staff','member')), primary key(server_id,user_id));
create table public.channels (id uuid primary key default gen_random_uuid(), server_id uuid not null references public.servers on delete cascade, name text not null check (char_length(name) between 1 and 40));
create table public.messages (id uuid primary key default gen_random_uuid(), channel_id uuid not null references public.channels on delete cascade, author_id uuid not null references public.profiles on delete cascade, body text not null check (char_length(body) between 1 and 2000), created_at timestamptz not null default now());
create index messages_channel_time on public.messages(channel_id, created_at);
create function public.is_member(sid uuid) returns boolean language sql security definer stable set search_path = public as $$ select exists(select 1 from members where server_id = sid and user_id = auth.uid()) $$;
create function public.is_staff(sid uuid) returns boolean language sql security definer stable set search_path = public as $$ select exists(select 1 from members where server_id = sid and user_id = auth.uid() and role in ('owner','staff')) $$;
create function public.create_server(server_name text) returns uuid language plpgsql security definer set search_path = public as $$
declare sid uuid;
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 insert into servers(name,owner_id) values(trim(server_name),auth.uid()) returning id into sid;
 insert into members(server_id,user_id,role) values(sid,auth.uid(),'owner');
 insert into channels(server_id,name) values(sid,'general');
 return sid;
end $$;
create function public.join_server(code text) returns uuid language plpgsql security definer set search_path = public as $$
declare sid uuid;
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 select id into sid from servers where invite_code = trim(code);
 if sid is null then raise exception 'Invitación inválida'; end if;
 insert into members(server_id,user_id) values(sid,auth.uid()) on conflict do nothing;
 return sid;
end $$;
create function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into profiles(id,username) values(new.id, left(coalesce(nullif(trim(new.raw_user_meta_data->>'username'),''), 'usuario'),32)); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
alter table public.profiles enable row level security;
alter table public.servers enable row level security;
alter table public.members enable row level security;
alter table public.channels enable row level security;
alter table public.messages enable row level security;
create policy profiles_read on profiles for select to authenticated using (id = auth.uid() or exists(select 1 from members m where m.user_id = profiles.id and public.is_member(m.server_id)));
create policy profiles_update on profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy servers_read on servers for select to authenticated using (public.is_member(id));
create policy members_read on members for select to authenticated using (public.is_member(server_id));
create policy channels_read on channels for select to authenticated using (public.is_member(server_id));
create policy channels_create on channels for insert to authenticated with check (public.is_staff(server_id));
create policy messages_read on messages for select to authenticated using (exists(select 1 from channels c where c.id = channel_id and public.is_member(c.server_id)));
create policy messages_create on messages for insert to authenticated with check (author_id = auth.uid() and exists(select 1 from channels c where c.id = channel_id and public.is_member(c.server_id)));
create policy messages_delete on messages for delete to authenticated using (author_id = auth.uid() or exists(select 1 from channels c where c.id = channel_id and public.is_staff(c.server_id)));
alter publication supabase_realtime add table public.messages;
