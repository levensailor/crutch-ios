-- Seed song: Way Too Much
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_18$Way Too Much$song_title_18$;
  v_lyrics text := $song_lyrics_18$Sorry, if I woke you up this morning
It was early
The sun was coming up and 
I've been drinking, too much
Drinking too much

Here I am, I'm just stumbling 
and I'm looking for a purpose
I'm just leaning and it's 
coming to the surface
Too much, always thinking too much

This conversations getting boring
I've given up and now I'm on the 
ground Way too much

Later on, I don't hope to find myself 
laid out in pieces
I've been scattered and divided for no reason
I don't know And it's hurting so much

Holding on, I am crashing for 
some way to stop this feeling
By replacing what Im feeling, am I sinking?
Too much, always thinking too much

This conversations getting boring
I've given up and now I'm on the ground
I'm slowly sinking into nothing
I've given up and now I'm on the ground
Way too much

I sink like a stone
Just like you knew I would, babe
Knew I would, babe x2$song_lyrics_18$;
  v_sort_order integer := 17;
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
