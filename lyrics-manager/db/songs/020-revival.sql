-- Seed song: Revival
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_20$Revival$song_title_20$;
  v_lyrics text := $song_lyrics_20$I am saved, I am saved
And oh, would you believe it?
All of the day
I felt his presence near me

I know they won't believe me, but
I've got favorite memories

I am saved, I am saved
And, oh, could you believe it?

You won't regret if you 
choose to believe it
Freedom, silence, always
All this darkness, always
Always

Oh, oh
Darkness, always, it don't make no sense
Darkness, always
Away from me darlin'$song_lyrics_20$;
  v_sort_order integer := 19;
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
