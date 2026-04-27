-- Seed song: Zero
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_21$Zero$song_title_21$;
  v_lyrics text := $song_lyrics_21$My reflection, dirty mirror
There's no connection to myself
I'm your lover, I'm your zero
I'm the face in your dreams of glass

So save your prayers
For when we're really gonna need them
Throw out your cares and fly
Wanna go for a ride?

She's the one for me
She's all I really need, oh yeah
She's the one for me
Emptiness is loneliness, 
and loneliness is cleanliness
And cleanliness is godliness, 
and God is empty Just like me

Intoxicated with the madness
I'm in love with my sadness
Bullshit fakers, enchanted kingdoms
Fashion victims chew their charcoal teeth

I never let on
That I was on a sinking ship
I never let on that I was down
You blame yourself
For what you can't ignore
You blame yourself for wanting more
She's the one for me
She's all I really need, oh yeah
She's the one for me
She's my one and only$song_lyrics_21$;
  v_sort_order integer := 20;
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
