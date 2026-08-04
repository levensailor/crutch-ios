alter table songs
add column if not exists hidden boolean not null default false;
