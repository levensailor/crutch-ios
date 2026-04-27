-- Seed song: King of the Beach
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_23$King of the Beach$song_title_23$;
  v_lyrics text := $song_lyrics_23$Let the sun burn my eyes
Let it burn my back

Let it sear through my thighs
Ill feel wide wide open

Let the sun burn my eyes
Let it burn my back

At the beach
In my dreams
But you still

Youre never gonna stop me
Youre never gonna stop me
Youre never gonna stop me
Youre never gonna stop

King of the beach
King of the beach

Let the sun burn my eyes
Let it burn my back

Let it burn through my thighs
Ill feel wide wide open

At the beach Im with Jeans
And its wide wide open

At the beach
In my dreams
But you still
#####
Youre never gonna stop me
Youre never gonna stop me
Youre never gonna stop me
Youre never gonna stop

King of the beach
Never gonna stop me

Youre never gonna stop me
Youre never gonna stop me
Youre never gonna stop

King of the beach
King of the beach
King of the beach
King of the beach
King of the beach$song_lyrics_23$;
  v_sort_order integer := 22;
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
