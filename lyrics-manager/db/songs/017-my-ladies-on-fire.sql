-- Seed song: My Ladies on Fire
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_17$My Ladies on Fire$song_title_17$;
  v_lyrics text := $song_lyrics_17$You say you want to cry
But your tears are dry
When I was that way
There's nothing left to say
Nothing left to say

Now my lady's on fire
She wants to tear it down
She knows you're a liar
My lady's on fire

She said, No, no, no, no, no, no
No, no, no, no, no, no, no, no
No, no, no, no, no
She said, No, no, nononono

Still I wonder why
Why he had to die
When I feel that way
There's nothing left to say
Nothing left to say

Still my lady's on fire
She wants to tear it down
She knows you're a liar
My lady's on fire

She said, No, no, no, no, no, no
No, no, no, no, no, no, no, no
No, no, no, no, no
She said, No, no, nononono$song_lyrics_17$;
  v_sort_order integer := 16;
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
