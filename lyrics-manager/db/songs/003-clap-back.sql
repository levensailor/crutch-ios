-- Seed song: Clap Back
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_3$Clap Back$song_title_3$;
  v_lyrics text := $song_lyrics_3$I didn't find out
You gonna get around, yeah
I didn't want that
You gonna look at me the same

I can snap back
You betta get ya ass on the table
I can slap back
You better simma down over there

You better get back
I got a cadillac and i'll run you over
I gotta clap back
Imma take none of that I see you waiting

I gotta fight that
You always get hacked, giving away
You got a big ass
I kinda like that, but you're over there

I gotta cigarette
I'm gonna smoke it, on the way
You're taking all of that
Long hair don't care, you gotta shave

I gotta cadillac
You got cataracts and everything's fuzzy
I gotta clap back
You better figure out, by yourself

My time is fight night
You gotta right the right, it's on the table
Ice cube studios
I keep oreos under my couch
I gotta fight back
You gonna fuck around and fall on faces$song_lyrics_3$;
  v_sort_order integer := 2;
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
