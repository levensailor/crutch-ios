-- Seed song: Demon to Lean On
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_6$Demon to Lean On$song_title_6$;
  v_lyrics text := $song_lyrics_6$You and I pace along the grass
And think of what we had
Ambivalent and young
We're probably just dumb

The truth is that it hurts
And what's it really worth?
No hope and no future

Holding a gun to my head
So send me an angel
Or bury me deeply instead
With demons to lean on

In the sky, it's never coming back
No hope and no future
We'll die the same loser

Holding a gun to my head
So send me an angel
Or bury me deeply instead
With demons to lean on
#####
Numb from it all
Not at all, at all, at all
Numb from it all
Not at all, at all, at all

Holding a gun to my head
So send me an angel
Or bury me deeply instead
With demons to lean on

Holding a gun to my head
So send me an angel
Or bury me deeply instead
With demons to lean on

Holding a gun to my head
Holding a gun to my head
Holding a gun to my head
With demons to lean on$song_lyrics_6$;
  v_sort_order integer := 5;
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
