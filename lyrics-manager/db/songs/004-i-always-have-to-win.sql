-- Seed song: I Always Have to Win
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_4$I Always Have to Win$song_title_4$;
  v_lyrics text := $song_lyrics_4$I will never be surprised
I only see what I wanna see
Every time that I look in you eyes

I can never compromise
And I only hear what I wanna hear
only say what sounds good at the time

I can always count on me
Thank you for the beer I spilt
That had some left and you just threw away

**I dont ever have regrets**
Its harder when Im hard
and Im staring down
Looking at your breasts

I wont over complicate
I wont tell you when you try too hard
Not listening to anything you say

I cant wait to fill you in
Theres too much always happening
And I dont mean to brag I mean
Its tough -- huh

**I always have to win**
The points you have dont make much sense
You reach straws + give false cause Im him

I always gotta have my way
I know that it sounds arrogant
But you know that Ill be right again today
#####
**I just have to stay inside**
Its not that I dont like the cold
I just think it fucks up
My whole vibe

**I will never let me down**
Im just too bad at everything
My expectations keep me on the ground

I would like to thank myself
I know its egotistical
Im fine with that
The best I ever felt - hah!

**I have never been scared**
Ive seen some shit I will admit
maybe im mid
but its hard to compare

I dont ever exercise
I pick things up so easily
My runners pulse, steady by my side - huh!

**I always pick the wine**
Cabernet Sav and Chardonay
Im making up my mind

**I am on the spectrum**
RGB and HSV anything as long as youre okay$song_lyrics_4$;
  v_sort_order integer := 3;
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
