-- Seed song: Humdrum 1
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_12$Humdrum 1$song_title_12$;
  v_lyrics text := $song_lyrics_12$Sometimes I just cant
Believe what I say
I open up and words come out

Im tired
Discombobulated
Shes always falling down

Stand up
Get right back in the scene
Now you know that Ive arrived

Its fine
Im out of time
So so long
Good bye

I want to dance
But you couldnt get down
With it I gave a shit

Im wired
Im wound up pitching a fit
He cant get used to this

Some time
Has passed out into the thick
Like wires in conduit

Hey hey
Fade away
But Ive got something
Ive got something to say
#####
Shut up
Cuz I dont even care that much
Hum drum my number one

I win
Youre my new cotter pin
Locked in and hauled away

Get out
I cant ever be late
I just cooperate

Lay down
Right now
Im gonna have to figure it
Gonna have to figure it outtt

Feels good
To not be misunderstood
I should be used to it

Dont stop
Even when I forgot
Its hard to concentrate

Youre right
I stay up too late in the night
Ill try to settle down

Stop your sighs
Im stopping by
To say good bye$song_lyrics_12$;
  v_sort_order integer := 11;
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
