-- Seed song: In The Mouth of a Desert
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_13$In The Mouth of a Desert$song_title_13$;
  v_lyrics text := $song_lyrics_13$Can you treat it like an oil well
When it's underground, out of sight?
And if the sight is just a whore sign
Can it make enough sense to me?
Pretend the table is a trust knot,
We'll put our labels down, faith is down
I'll watch the yarn of twine unravel
And you'll never get it back

It's what I want (it's what I want)
It's what I want (twine comes down)
It's what I want, it's what I want
Don't you know, I could make you try
Make you try, make you try, make you try

I've been crowned the King of Id
And Id is all we have, so wait
To hear my words and they're diamond-sharp
I could open it up And it's up and down

Ooh-ooh-ooh-ooh, ooh-ooh-ooh-ooh x4

It's what I want (it's what I want)
I see you beg like a little dog 
(ball and twine)
Don't you know that it's what I want? 
(It's what I want)
I'll see you beg, and it makes you dry
Make me dry, make me dry, make me dry

I've been down, the King of Ids
Id's all we have, I've been down
And I could wait to hear the words
They're diamond-sharp today

Ooh-ooh-ooh-ooh, ooh-ooh-ooh-ooh x4$song_lyrics_13$;
  v_sort_order integer := 12;
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
