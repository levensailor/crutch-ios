-- Seed song: Human Performance
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_15$Human Performance$song_title_15$;
  v_lyrics text := $song_lyrics_15$I know exactly where I was when I
First saw you the way I see you now, 
through these eyes, waiting to retry

Those pristine days I recall so fondly
So few are trials when a life isn't lonely, 
and now if only

I'd never felt it, I'd never heard it
I know I loved you, did I even deserve it, 
when you returned it?

There's no suspicion, no hesitation
Believing through the eyes of sore, adoration

Witness and know, fracture and hurt
Eyes in the fire, blink unrehearsed

Shield like a house, closing its doors
Curved in the dark, rinses of yours

Ashtray is crowded, bottle is empty
No music plays and nothing moves 
without drifting, into a memory

Busy apartment, no room for grieving
Sink full of dishes and no trouble
believing, that you are leaving

Mid-sentence tremors, mind at its weakest
One way of shaking off the thoughts 
that it sleeps with
#####
Witness and know, fracture and hurt
Eyes in the fire, blink unrehearsed
Shield like a house, closing its doors
Curved in the dark, rinses of yours

In walks the darkness, I pitch without you
Asks me do I realize what I'd done 
and who I'd done to, indeed I do know?

It never leaves me, just visits less often
It isn't gone and I won't feel its 
grip soften, without a coffin

Breathing beside me, feeling its warmness
Phantom affection gives a human performance

Witness and know, fracture and hurt
Eyes in the fire, blink unrehearsed
Shield like a house, closing its doors
Curved in the dark, rinses of yours$song_lyrics_15$;
  v_sort_order integer := 14;
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
