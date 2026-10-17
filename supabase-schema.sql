-- Run in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 role text not null default 'buyer' check(role in ('buyer','seller')),
 country_code text,
 created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "Profiles are publicly viewable" on public.profiles;
create policy "Profiles are publicly viewable" on public.profiles for select using(true);
drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile" on public.profiles for insert with check(auth.uid()=id);
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update using(auth.uid()=id) with check(auth.uid()=id);
create table if not exists public.listings (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid not null references auth.users(id) on delete cascade,
 title text not null check(char_length(title) between 3 and 100),
 description text not null default '' check(char_length(description)<=1500),
 listing_type text not null check(listing_type in ('product','service')),
 price_kobo bigint not null check(price_kobo>0),
 currency char(3) not null default 'NGN',
 image_url text,
 status text not null default 'active' check(status in ('active','paused','sold','removed')),
 created_at timestamptz not null default now()
);
alter table public.listings enable row level security;
drop policy if exists "Public read active listings" on public.listings;
create policy "Public read active listings" on public.listings for select using(status='active' or auth.uid()=seller_id);
drop policy if exists "Seller insert own listings" on public.listings;
create policy "Seller insert own listings" on public.listings for insert with check(auth.uid()=seller_id);
drop policy if exists "Seller update own listings" on public.listings;
create policy "Seller update own listings" on public.listings for update using(auth.uid()=seller_id) with check(auth.uid()=seller_id);
drop policy if exists "Seller delete own listings" on public.listings;
create policy "Seller delete own listings" on public.listings for delete using(auth.uid()=seller_id);
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(),
 buyer_id uuid not null references auth.users(id),
 seller_id uuid not null references auth.users(id),
 listing_id uuid not null references public.listings(id),
 amount_kobo bigint not null check(amount_kobo>0),
 commission_kobo bigint not null default 0 check(commission_kobo>=0),
 currency char(3) not null default 'NGN',
 status text not null default 'pending' check(status in ('pending','paid','completed','cancelled','refunded')),
 provider_reference text unique,
 created_at timestamptz not null default now(),
 completed_at timestamptz
);
alter table public.orders enable row level security;
drop policy if exists "Buyer seller read own orders" on public.orders;
create policy "Buyer seller read own orders" on public.orders for select using(auth.uid()=buyer_id or auth.uid()=seller_id);
-- Intentionally no client-side order insert/update policies. A trusted server must
-- validate the price, verify provider webhooks, calculate commission, and update order status.
create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,display_name,role)
 values(new.id,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1)),
 case when new.raw_user_meta_data->>'role'='seller' then 'seller' else 'buyer' end)
 on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users for each row execute procedure public.create_profile_for_new_user();
