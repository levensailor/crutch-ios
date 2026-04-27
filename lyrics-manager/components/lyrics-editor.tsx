"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { autoAddPageMarkers, renderInlineMarkers, splitByPageMarkers } from "@/lib/lyrics-markers";
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
  const textareaRef = useRef<HTMLTextAreaElement | null>(null);
  const saveFormId = song ? `song-save-${song.id}` : "song-save-new";
  const pages = useMemo(() => splitByPageMarkers(lyrics), [lyrics]);
  const currentPage = pages[Math.min(pageIndex, pages.length - 1)] ?? "";
  const currentPageLineCount = currentPage ? currentPage.split(/\r?\n/).length : 0;
  const isDensePage = currentPageLineCount > 28 || currentPage.length > 850;

  useEffect(() => {
    setPageIndex(0);
  }, [lyrics]);

  function wrapSelection(openMarker: string, closeMarker = openMarker) {
    const textarea = textareaRef.current;

    if (!textarea) {
      return;
    }

    const selectionStart = textarea.selectionStart;
    const selectionEnd = textarea.selectionEnd;
    const selectedText = lyrics.slice(selectionStart, selectionEnd);

    if (!selectedText) {
      textarea.focus();
      return;
    }

    const hasSelectedMarkers =
      selectedText.startsWith(openMarker) && selectedText.endsWith(closeMarker);
    const replacement = hasSelectedMarkers
      ? selectedText.slice(openMarker.length, selectedText.length - closeMarker.length)
      : `${openMarker}${selectedText}${closeMarker}`;
    const nextLyrics =
      lyrics.slice(0, selectionStart) + replacement + lyrics.slice(selectionEnd);

    setLyrics(nextLyrics);

    requestAnimationFrame(() => {
      textarea.focus();
      textarea.setSelectionRange(selectionStart, selectionStart + replacement.length);
    });
  }

  function addAutomaticPageBreaks() {
    const nextLyrics = autoAddPageMarkers(lyrics);
    setLyrics(nextLyrics);
    setPageIndex(0);

    requestAnimationFrame(() => {
      textareaRef.current?.focus();
    });
  }

  return (
    <div className="editor-grid">
      <section className="panel">
        <form action={saveAction} id={saveFormId}>
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
            <div className="editor-toolbar" aria-label="Lyrics formatting tools">
              <button
                className="toolbar-button pink"
                onClick={() => wrapSelection("**")}
                type="button"
              >
                Pink cue
              </button>
              <button
                className="toolbar-button green"
                onClick={() => wrapSelection("~~")}
                type="button"
              >
                Green cue
              </button>
              <button className="toolbar-button" onClick={addAutomaticPageBreaks} type="button">
                Auto add page breaks
              </button>
            </div>
            <textarea
              className="textarea"
              id="lyrics"
              name="lyrics"
              onChange={(event) => setLyrics(event.target.value)}
              ref={textareaRef}
              value={lyrics}
            />
            <p className="editor-help">
              Select text and choose a cue color. The editor saves markers so the iPhone app keeps
              its current rendering behavior.
            </p>
          </div>

        </form>

        <div className="editor-actions">
          {deleteAction ? (
            <form action={deleteAction}>
              <button className="button danger" type="submit">
                Delete song
              </button>
            </form>
          ) : null}
          <button className="button" form={saveFormId} type="submit">
            Save lyrics
          </button>
        </div>
      </section>

      <aside>
        <section className="panel" style={{ marginBottom: 20 }}>
          <div className="eyebrow">Writing guide</div>
          <h2>Fit the performance screen</h2>
          <ul className="guide-list">
            <li>Use short lines. The app renders bold 18pt text in a non-scrolling page.</li>
            <li>Use Auto add page breaks for a first pass, then adjust markers by hand.</li>
            <li>Insert a line with <strong>#####</strong> where the performer should turn pages.</li>
            <li>Select text and click Pink cue or Green cue instead of typing markers manually.</li>
            <li>The saved text still uses <strong>**text**</strong> and <strong>~~text~~</strong> so iOS stays compatible.</li>
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
