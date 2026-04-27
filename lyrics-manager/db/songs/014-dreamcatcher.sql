-- Seed song: Dreamcatcher
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_14$Dreamcatcher$song_title_14$;
  v_lyrics text := $song_lyrics_14$Dreamcatcher x4

Well I just checked the mail and found your note
I was looking down my eyes so low
And next time you come this way ill go slow-ew-oh

Dreamcatcher x4

And Ill be back again before you know
And this time youll be begging me for more
Well go back and forth until you soar

Dreamcatcher x4

Im waiting waiting waiting by the phone
Wanting wishing hating feeling bored
The good thing is youll never really know

Dreamcatcher x4

**[Solo 4th string 3rd dot]**

**Dreamcatcher**

I hate to say I gotta let you go
You said do you hate me I said no
One thing that I know is I got row

And sometime when youre ready Ill be him
Unless I found another to begin
And that time Ill do everything I can
To dream again the good things and the bad

Dreamcatcher

Dreamcatcher$song_lyrics_14$;
  v_sort_order integer := 13;
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
