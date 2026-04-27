import Link from "next/link";
import { SortableSongList } from "@/components/sortable-song-list";
import { listSongs } from "@/lib/songs";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const songs = await listSongs();

  return (
    <main className="page-shell">
      <div className="header-row">
        <div>
          <div className="eyebrow">Crutch</div>
          <h1 className="title">Lyrics Manager</h1>
          <p className="muted">
            Public editor for performance lyrics, marker-defined pages, and the iOS app feed.
          </p>
        </div>
        <Link className="button" href="/songs/new">
          New song
        </Link>
      </div>

      <section className="panel">
        {songs.length === 0 ? (
          <p className="muted">No songs yet. Create the first song to publish the app feed.</p>
        ) : (
          <SortableSongList songs={songs} />
        )}
      </section>
    </main>
  );
}
