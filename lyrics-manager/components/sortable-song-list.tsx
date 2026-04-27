"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import type { SongRecord } from "@/lib/schemas";

type SortableSongListProps = {
  songs: SongRecord[];
};

export function SortableSongList({ songs }: SortableSongListProps) {
  const router = useRouter();
  const [orderedSongs, setOrderedSongs] = useState(songs);
  const [draggedSongId, setDraggedSongId] = useState<string | null>(null);
  const [status, setStatus] = useState<string | null>(null);
  const songIds = useMemo(() => orderedSongs.map((song) => song.id), [orderedSongs]);

  useEffect(() => {
    setOrderedSongs(songs);
  }, [songs]);

  async function persistOrder(nextSongs: SongRecord[]) {
    setStatus("Saving order...");

    const response = await fetch("/api/songs/reorder", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ songIds: nextSongs.map((song) => song.id) }),
    });

    if (!response.ok) {
      setOrderedSongs(songs);
      setStatus("Could not save order. Refresh and try again.");
      return;
    }

    setStatus("Order saved.");
    router.refresh();
  }

  function moveSong(targetSongId: string) {
    if (!draggedSongId || draggedSongId === targetSongId) {
      return;
    }

    const draggedIndex = songIds.indexOf(draggedSongId);
    const targetIndex = songIds.indexOf(targetSongId);

    if (draggedIndex < 0 || targetIndex < 0) {
      return;
    }

    const nextSongs = [...orderedSongs];
    const [draggedSong] = nextSongs.splice(draggedIndex, 1);
    nextSongs.splice(targetIndex, 0, draggedSong);
    setOrderedSongs(nextSongs);
    void persistOrder(nextSongs);
  }

  return (
    <>
      <ul className="song-list">
        {orderedSongs.map((song, index) => (
          <li
            className="sortable-song"
            key={song.id}
            onDragOver={(event) => event.preventDefault()}
            onDrop={() => moveSong(song.id)}
          >
            <button
              aria-label={`Drag ${song.title} to reorder`}
              className="drag-handle"
              draggable
              onDragEnd={() => setDraggedSongId(null)}
              onDragStart={() => setDraggedSongId(song.id)}
              type="button"
            >
              {index + 1}
            </button>
            <Link href={`/songs/${song.id}`}>
              <span className="song-title">{song.title}</span>
              <span className="muted">Edit lyrics</span>
            </Link>
          </li>
        ))}
      </ul>
      {status ? <p className="sort-status">{status}</p> : null}
    </>
  );
}
