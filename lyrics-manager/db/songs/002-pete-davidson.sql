-- Seed song: Pete Davidson
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_2$Pete Davidson$song_title_2$;
  v_lyrics text := $song_lyrics_2$I look cool when im with my friends
i live in a basement
my mom is my best friend
im pete davidson

I don’t dance and I got tattoos
I’m always down to booze
My eyes are sinking in
Im Pete Davidson

**What is wrong**
**What is wrong with me**
**What is wrong**
**What is wrong with me**

Why the fuck am I in Utah?
I can’t get high anymore
I pretend that I got the bends
Im Pete Davidson

I listen to your advice
What the fuck did she say?
Its okay were just good friends
Kim kardashian
Kim Kardashian WEST!

**All of, All of my life**
**Allllll of myyy liiiifeee, oooh ewwooo!**

Kanye DMd I got the hiv
Im gonna get checked out
Feels like im never gonna win
Im Pete Davidson
#####
My moms boyfriend is moving in
and I gotta move out
Feels like the walls are closing in
Ann coulter is here
Ann coulter is here!

**all of, all of my life**
**borderline, borderline!!**

people say i got butthole eyes
and im not surprised
they dont know i got crohns
but i will survive i will **survive..**$song_lyrics_2$;
  v_sort_order integer := 1;
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
