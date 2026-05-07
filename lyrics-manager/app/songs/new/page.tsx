import Link from "next/link";
import { createSongAction } from "@/app/actions";
import { LyricsEditor } from "@/components/lyrics-editor";

export default function NewSongPage() {
  return (
    <main className="page-shell">
      <div className="header-row">
        <div className="eyebrow">New song</div>
        <Link className="button secondary" href="/">
          Back to songs
        </Link>
      </div>

      <LyricsEditor saveAction={createSongAction} />
    </main>
  );
}
