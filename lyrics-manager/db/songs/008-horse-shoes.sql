-- Seed song: Horse Shoes
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_8$Horse Shoes$song_title_8$;
  v_lyrics text := $song_lyrics_8$I know you
I know, but I don't know what to do
You say, oh everything you say
We're born to lose
I know you
I know, but I don't know what to do
You say, oh everything you say
We're born to lose

Could you ride with a horse, no shoes?
Cause there's nothing that I won't do
And there's nowhere else, 
there's no more going

I know you
I know, but I don't know what to do
You know, well you're a know it all
We're born to lose
I know you
I know, but I don't know what to do
You say, oh everything you say
We're born to lose

Could you ride with a horse, no shoes?
Cause there's nothing that I won't do
And there's nowhere else, 
there's no more going

Could you ride with a horse, no shoes?
Cause there's nothing that I won't do
And there's nowhere else, 
there's no more going$song_lyrics_8$;
  v_sort_order integer := 7;
begin
  update songs
  set lyrics = v_lyrics,
      sort_order = v_sort_order
  where title = v_title;

  if not found then
    insert into songs (title, lyrics, sort_order)
    values (v_title, v_lyrics, v_sort_order);
  end if;
end $$;
