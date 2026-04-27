-- Seed song: All Alone and Tired
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_7$All Alone and Tired$song_title_7$;
  v_lyrics text := $song_lyrics_7$I was having some fun
Im so dumb
Oh my god Im so **fucked**

I fell off the back
I wanna go back
I just had to pee

I took off of work
Auto reply
Please dont be talking to me

I went to get bait
Was gonna be late
I just had to **fish**

**I dont wanna die**
**I wanna live**
**Theyre coming after me**
**I wanna fly, I wanna fly**
**Too far for you to see**

**When** I fell off the boat
I started to float
I cant see shit
Its insane

I took off my boots
Swimming in suits
All alone and tired

I needed some help
I just fell 
And it was all of my **fault**
#####
**Help! Help!**
**Gimme some help, I need some help**
**Help me Im saying goodbye**

**I dont wanna die, I dont wanna die**
**Please come after me**

**I dont wanna die, I dont wanna die**
**Too far for you to see**

**Help! Help! Gimme some Help**
**I need some help**
**They ll never find me alive**
**I dont wanna die, I dont wanna die**
**Please help me!!!!**

SOLO

**Help! Help! Gimme some help**
**I need some help**
**Help them to find me alive**
**Help! Help! Gimme some help**
**I need some help**
**Theyll never find me alive**

OUTRO
I dont wanna die x2
I dont wanna die x2
Please help me$song_lyrics_7$;
  v_sort_order integer := 6;
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
