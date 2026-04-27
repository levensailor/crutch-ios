-- Seed song: South of France
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_10$South of France$song_title_10$;
  v_lyrics text := $song_lyrics_10$Drivin' in the south of France
And I'm blastin' Abba
Moroccan guy askin me
A sensual question
Lookin' at the beach
It's a shame
That it's a-rainin'
I wish I could take a swim
Instead I'm stuck in a cab with a stranger
Drank last night and I feel like shit

I hate every book I ever read
Take back the words I never said
I need somewhere to rest my head
I'm lookin' for a big old, big old med

Two years later I'm back in the same town
This time I brought my girlfriend
We fought at the beach and slept at a fish shop
We told each other it was the end
All the girls on the beach all topless and tan
Real pretty bodies but with faces like men
I wish I was different
More like the fall
But every time I try I realize I can't

I hear a party in room 13
I can hear all of them people scream
Ever wait four years at the fucked up drape
I'm just gonna wait for the next day
#####
Next day I wake up
I drink coffee
And I go for a walk around town
Buy some drugs off a street man
Go back to the hotel
Lie back down
I'm thinkin' there's a gas leak in my room
I'm on drugs
I'm freakin' out
Do I call the deskman and tell him
Or do I just go back to sleep?

I hate every book I ever read
Take back the words you never said
I need somewhere to rest my head
I'm lookin' for a big old, big old med$song_lyrics_10$;
  v_sort_order integer := 9;
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
