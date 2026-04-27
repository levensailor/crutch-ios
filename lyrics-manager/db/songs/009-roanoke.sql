-- Seed song: Roanoke
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_9$Roanoke$song_title_9$;
  v_lyrics text := $song_lyrics_9$I missed the bus, was on the phone
Now Im stuck here all alone
Don’t be crazy when Im..
Trying my best (im trying my best)

I caught a ride to Roanoke
Croatoan I misspoke
I was wasted maybe
But I didnt know I didnt know (wooh!)

**I didnt know.. I didnt, I didnt know**
**I didnt know x3**

Dude was always talking smack
I heard your name and had your back
Thought I missed it but its
Always the same (its always the same)

Took a plane to Tokyo
But where I landed I don’t know
Seemed kind of weird at first but
daijoubu desu daijoubu desu (wooh!)

**I didnt know.. I didnt, I didnt know**
**I didnt know x3**

**Ill never be defeated (yeah)**
**Im gonna put my feet up (yeah)**
**You can find me all fd up in the air**

**Ill never be defeated (yeah)**
**Im gonna put my feet up (yeah)**
**You can find me all fd up in the air**

**(doo-doo-doo doo doo)**
#####
Can I ask just where youre from
1890s Oregon?

You talking faster but its
Not just the same (its just not the same)

Always sunny on the bed
I turned it off and then you said

Im kinda bossy sometimes but
I didnt care (You didnt care) (wooh!)

**I didnt care, and you didnt, you didnt care**
**i didnt care x3**

**Im in heaven**
**I see eyes**
**Come and take me into**
**Your green eyes, your green eyes**

**Ill never be defeated (yeah)**
**Im gonna put my feet up (yeah)**
**You can find me all fd up in the air**

**Ill never be defeated (yeah)**
**Im gonna put my feet up (yeah)**
**You can find me all fd up in the air**
hold for an extra measure, loud eighth notes

**(doo-doo-doo doo doo)**$song_lyrics_9$;
  v_sort_order integer := 8;
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
