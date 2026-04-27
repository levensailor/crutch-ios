-- Seed song: My Kind of Woman
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_19$My Kind of Woman$song_title_19$;
  v_lyrics text := $song_lyrics_19$Oh, baby - Oh, man
You're makin' me crazy
Really drivin' me mad

That's alright with me
It's really no fuss
As long as you're next to me
Just the two of us

You're my, my, my, my kind of woman
My, oh my, what a girl
You're my, my, my, my kind of woman

And I'm down on my hands and knees
Beggin' you please, baby
Show me your world

Oh, brother - Sweetheart
I'm feelin' so tired
Really fallin' apart

And it just don't make sense to me
I really don't know
Why you stick right next to me
Wherever I go

You're my, my, my, my kind of woman
My, oh my, what a girl
You're my, my, my, my kind of woman

And I'm down on my hands and knees
Beggin' you please, baby
Show me your world$song_lyrics_19$;
  v_sort_order integer := 18;
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
