-- Seed song: Memories Can't Wait
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_11$Memories Can't Wait$song_title_11$;
  v_lyrics text := $song_lyrics_11$Do you remember anyone here?
No you don't remember anything at all
I'm sleeping, I'm flat on my back
Never woke up, had no regrets

There's a party in my mind... 
And I hope it never stops
There's a party up there all the time... 
They'll party till they drop

Other people can go home... 
Everyone else will split
I'll be here all the time. I can never quit

Take a walk through the land of shadows
Take a walk through the peaceful meadows
Try not to look so disappointed
It isn't what you hoped for, is it?

There's a party in my mind... 
And I hope it never stops
I'm stuck here in this seat... 
I might not stand up

Other people can go home... 
Other people can split
I'll be here all the time... 
I can never quit

Everything is very quiet
Everyone has gone to sleep
I'm wide awake on memories
These memories can't wait.$song_lyrics_11$;
  v_sort_order integer := 10;
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
