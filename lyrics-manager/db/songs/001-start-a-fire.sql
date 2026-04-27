-- Seed song: Start a Fire
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_1$Start a Fire$song_title_1$;
  v_lyrics text := $song_lyrics_1$hey-im gonna go to the beach x3
i got sand in my sheets
gimme I I gimme ugh gimme I I
gimme I I gimme ayay

hey-im gonna go to the beach x3
i got sand in my sheets
gimme i i gimme ugh gimme I I
gimme I I gimme ayay

Always hangin round down town
Got the banger sound
Found another spot on the ground
With some beers I found

Always talking shit in my whip
With some things Im trying
Hang my new threads up
while the rest, well the rest is dryin

~~Hey Im gonna start a fire~~
~~Im gonna start a fire~~
~~Im gonna dig in the dirt~~

~~Gimme I I gimme ugh gimme I I~~
~~gimme I I gimme ayay~~

Figures in my head go to bed
Left a light on trying
Not so new repeat, Portuguese
quero ir a praia

Chillin in the hood mt hood
see the heli coming
running to the sun gimme some
Accommodations
#####
Pitching up my tent
getting bent with the bento prying
Tail up on my face and I
slap it up and down I fell in

got the blues clues
with the drip drip kinda nice
pack you up myself hit it twice
twice paradise

~~Hey Im gonna start a fire x3~~
~~Im gonna dig in the dirt~~
~~gimme I I gimme ugh gimme I I~~
~~gimme I I gimme ayay~~

**Hey Im gonna start a fire**
**Im gonna start a fire, gonna start a fire**
**Gimme I ugh gimme ugh ugh**
**I gimme ugh I gimme gimme ayay**

**Hey im gonna go-to-the-beach**
**Hey im gonna get-my-rel-ease**

**Lemme start a fire ((to the place)) Im trying**
**notso new repeat Portuguese quero ira praia**
**got the hoody hood mt hood**
**See the heli comin**
**Gimme some of your, your accomodations**

**hey im gonna go to the beach x3**
**i got sand in my sheets**
**gimme I I gimme ugh gimme I I**
**gimme ugh ugh gimme uhuhuhuh**
Bum bum - bum bum bum bum bum(ending)$song_lyrics_1$;
  v_sort_order integer := 0;
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
