create extension if not exists pgcrypto;

create table if not exists songs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  lyrics text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists songs_sort_order_idx on songs (sort_order, title);
create index if not exists songs_updated_at_idx on songs (updated_at desc);

create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists songs_set_updated_at on songs;
create trigger songs_set_updated_at
before update on songs
for each row
execute function set_updated_at();
