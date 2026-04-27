-- Seed song: Look Like That
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_16$Look Like That$song_title_16$;
  v_lyrics text := $song_lyrics_16$I like his shoes I like his hat
I'd like me better if I looked like that
Uh -huh uh-huh

I like her shoes I like her hat
I'd like you better if you looked like that
Uh-huh uh-huh

But then my love starts burning
For what we are yearning to ignore

I like her clothes I love her dress
I'd like her better if she loved me best

I like his shoes I love his pants
I'd want him better if he wanted to dance
Uh-huh uh-huh

But then our love starts turning
For what we are learning to adore

I'm meeting people nice people too
I'm meeting people nice people like you
We're meeting people nice people too
We're meeting people nice people like you$song_lyrics_16$;
  v_sort_order integer := 15;
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
