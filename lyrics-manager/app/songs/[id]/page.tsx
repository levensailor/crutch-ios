import Link from "next/link";
import { notFound } from "next/navigation";
import { deleteSongAction, updateSongAction } from "@/app/actions";
import { LyricsEditor } from "@/components/lyrics-editor";
import { getSong } from "@/lib/songs";

export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{
    id: string;
  }>;
};

export default async function EditSongPage({ params }: PageProps) {
  const { id } = await params;
  const song = await getSong(id);

  if (!song) {
    notFound();
  }

  const saveAction = updateSongAction.bind(null, song.id);
  const deleteAction = deleteSongAction.bind(null, song.id);

  return (
    <main className="page-shell">
      <div className="header-row">
        <div>
          <div className="eyebrow">Edit song</div>
          <h1 className="title">{song.title}</h1>
        </div>
        <Link className="button secondary" href="/">
          Back to songs
        </Link>
      </div>

      <LyricsEditor deleteAction={deleteAction} saveAction={saveAction} song={song} />
    </main>
  );
}
