alter table songs
add column if not exists tabs jsonb not null default '{"version":1,"pages":[]}'::jsonb;
