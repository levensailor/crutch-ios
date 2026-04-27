"use client";

import { useEffect, useMemo, useState } from "react";
import { renderInlineMarkers, splitByPageMarkers } from "@/lib/lyrics-markers";
import type { SongRecord } from "@/lib/schemas";

type LyricsEditorProps = {
  song?: SongRecord;
  saveAction: (formData: FormData) => Promise<void>;
  deleteAction?: (formData: FormData) => Promise<void>;
};

export function LyricsEditor({ song, saveAction, deleteAction }: LyricsEditorProps) {
  const [title, setTitle] = useState(song?.title ?? "");
  const [lyrics, setLyrics] = useState(song?.lyrics ?? "");
  const [pageIndex, setPageIndex] = useState(0);
  const pages = useMemo(() => splitByPageMarkers(lyrics), [lyrics]);
  const currentPage = pages[Math.min(pageIndex, pages.length - 1)] ?? "";
  const currentPageLineCount = currentPage ? currentPage.split(/\r?\n/).length : 0;
  const isDensePage = currentPageLineCount > 28 || currentPage.length > 850;

  useEffect(() => {
    setPageIndex(0);
  }, [lyrics]);

  return (
    <div className="editor-grid">
      <section className="panel">
        <form action={saveAction}>
          <div className="field-stack">
            <label htmlFor="title">Song name</label>
            <input
              className="input"
              id="title"
              name="title"
              onChange={(event) => setTitle(event.target.value)}
              required
              value={title}
            />
          </div>

          <div className="field-stack">
            <label htmlFor="sortOrder">Sort order</label>
            <input
              className="input"
              id="sortOrder"
              min="0"
              name="sortOrder"
              type="number"
              defaultValue={song?.sortOrder ?? 0}
            />
          </div>

          <div className="field-stack">
            <label htmlFor="lyrics">Lyrics</label>
            <textarea
              className="textarea"
              id="lyrics"
              name="lyrics"
              onChange={(event) => setLyrics(event.target.value)}
              value={lyrics}
            />
          </div>

          <div className="action-row">
            <button className="button" type="submit">
              Save lyrics
            </button>
          </div>
        </form>

        {deleteAction ? (
          <form action={deleteAction} className="action-row" style={{ marginTop: 12 }}>
            <button className="button danger" type="submit">
              Delete song
            </button>
          </form>
        ) : null}
      </section>

      <aside>
        <section className="panel" style={{ marginBottom: 20 }}>
          <div className="eyebrow">Writing guide</div>
          <h2>Fit the performance screen</h2>
          <ul className="guide-list">
            <li>Use short lines. The app renders bold 18pt text in a non-scrolling page.</li>
            <li>Insert a line with <strong>#####</strong> where the performer should turn pages.</li>
            <li>Keep page breaks intentional. The app does not auto-split long lyrics.</li>
            <li>Wrap <strong>**text**</strong> for pink highlight cues.</li>
            <li>Wrap <strong>~~text~~</strong> for green highlight cues.</li>
            <li>Use the simulator to catch pages that feel too dense before a show.</li>
          </ul>
        </section>

        <section className="panel">
          <div className="eyebrow">iPhone 16 Pro simulator</div>
          <h2>{title || "Untitled song"}</h2>
          <div className="phone-frame">
            <div className="phone-screen">
              <div
                className="simulated-lyrics"
                dangerouslySetInnerHTML={{ __html: renderInlineMarkers(currentPage) }}
              />
              <div className="simulator-page-count">
                Page {Math.min(pageIndex + 1, pages.length)} / {pages.length}
              </div>
            </div>
          </div>
          <div className="page-controls">
            <button
              className="button secondary"
              disabled={pageIndex === 0}
              onClick={() => setPageIndex((value) => Math.max(0, value - 1))}
              type="button"
            >
              Previous
            </button>
            <button
              className="button secondary"
              disabled={pageIndex >= pages.length - 1}
              onClick={() => setPageIndex((value) => Math.min(pages.length - 1, value + 1))}
              type="button"
            >
              Next
            </button>
          </div>
          <p className={isDensePage ? "density-warning" : "muted"}>
            {currentPageLineCount} lines on this page
            {isDensePage
              ? ". This may be too dense for the iPhone stage view."
              : ". This should be readable if the lines stay short."}
          </p>
        </section>
      </aside>
    </div>
  );
}
