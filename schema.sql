-- My Finance / Supabase schema
-- Run this entire script in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  account_type text not null default '銀行帳戶',
  purpose text,
  opening_balance numeric(14,2) not null default 0,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  type text not null check (type in ('income','expense','transfer')),
  amount numeric(14,2) not null check (amount > 0),
  date date not null,
  status text not null default 'actual' check (status in ('actual','planned')),
  category text,
  account_id uuid not null references public.accounts(id) on delete restrict,
  to_account_id uuid references public.accounts(id) on delete restrict,
  note text,
  reminder text,
  created_at timestamptz not null default now(),
  constraint transfer_target_required check ((type = 'transfer' and to_account_id is not null and to_account_id <> account_id) or (type <> 'transfer' and to_account_id is null))
);

create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  month text not null check (month ~ '^\d{4}-\d{2}$'),
  category text not null,
  amount numeric(14,2) not null check (amount >= 0),
  note text,
  created_at timestamptz not null default now(),
  unique(user_id, month, category)
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  target_amount numeric(14,2) not null check (target_amount > 0),
  current_amount numeric(14,2) not null default 0 check (current_amount >= 0),
  due_date date,
  account_id uuid references public.accounts(id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists transactions_user_date_idx on public.transactions(user_id, date desc);
create index if not exists accounts_user_idx on public.accounts(user_id);
create index if not exists budgets_user_month_idx on public.budgets(user_id, month);
create index if not exists goals_user_idx on public.goals(user_id);

alter table public.accounts enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.goals enable row level security;

drop policy if exists "users manage own accounts" on public.accounts;
create policy "users manage own accounts" on public.accounts for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "users manage own transactions" on public.transactions;
create policy "users manage own transactions" on public.transactions for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "users manage own budgets" on public.budgets;
create policy "users manage own budgets" on public.budgets for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "users manage own goals" on public.goals;
create policy "users manage own goals" on public.goals for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Ensure referenced accounts belong to the same user (defence in depth).
create or replace function public.check_transaction_accounts_owner()
returns trigger language plpgsql security invoker as $$
begin
  if not exists (select 1 from public.accounts a where a.id = new.account_id and a.user_id = new.user_id) then
    raise exception '來源帳戶不存在或不屬於目前使用者';
  end if;
  if new.to_account_id is not null and not exists (select 1 from public.accounts a where a.id = new.to_account_id and a.user_id = new.user_id) then
    raise exception '轉入帳戶不存在或不屬於目前使用者';
  end if;
  return new;
end; $$;
drop trigger if exists transactions_accounts_owner on public.transactions;
create trigger transactions_accounts_owner before insert or update on public.transactions for each row execute function public.check_transaction_accounts_owner();
