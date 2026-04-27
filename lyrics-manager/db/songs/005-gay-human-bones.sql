-- Seed song: Gay Human Bones
-- Run manually after lyrics-manager/db/001_create_songs.sql.
-- This script is idempotent by title.

do $$
declare
  v_title text := $song_title_5$Gay Human Bones$song_title_5$;
  v_lyrics text := $song_lyrics_5$I just wanna see Jay hard
Just so. we're cool. 
They know they're good
Yeah it's pretty hard getting sick of what-
Ever you're going through

I know, I know, I know, I know

My basketball team's name is 
Gay Human Bones
We win most of the games 
that we play at home
Oh yeah, that idea, yeah, it's a good one
We just found out
You're gon get off & the ball is fucking ours
Or so they tell me

I found a good shooter while I was on
Oh Lord, I was stoned
Water moccasins crawling through my hell
Oh yeah, I know I'm all alone

I know, I know, I know, I know

My basketball team's name is 
Gay Human Bones
We win most of the games 
that we play at home
Oh yeah, that idea, yeah, it's a good one
We just fucked up You're gonna get off 
and your ball is fucking ours x2$song_lyrics_5$;
  v_sort_order integer := 4;
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
