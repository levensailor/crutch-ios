-- Seed song: Linus Spacehead
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_22$Linus Spacehead$song_title_22$;
  v_lyrics text := $song_lyrics_22$**wooo x4**

My feet
Are asleep
My hands
Chained to clouds

**wooo x4**
My toes
Are marble stones
Sinking in the sand
**wooo x4**

**Im stuck in the sky**
**Im never coming down**

DRUM SOLO

**wooo x4**

**Im stuck in the sky**
**Im never coming down**
**Im stuck in the ground**
**Im never getting out**

**wooo x8**$song_lyrics_22$;
  v_sort_order integer := 21;
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
