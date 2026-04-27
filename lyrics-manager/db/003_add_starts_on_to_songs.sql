alter table songs
add column if not exists starts_on text not null default '';
