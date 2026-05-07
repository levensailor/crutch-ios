"use client";

import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
} from "react";
import { autoAddPageMarkers, renderInlineMarkers, splitByPageMarkers } from "@/lib/lyrics-markers";
import {
  EMPTY_SONG_TABS,
  TAB_NOTES,
  type SongRecord,
  type SongTabs,
  type TabNote,
  type TabPage,
  type TabPlacement,
} from "@/lib/schemas";

type LyricsEditorProps = {
  song?: SongRecord;
  saveAction: (formData: FormData) => Promise<void>;
  deleteAction?: (formData: FormData) => Promise<void>;
};

type DragState = {
  note: TabNote;
  pointerId: number;
  offsetX: number;
  offsetY: number;
};

const PILL_WIDTH = 44;
const PILL_HEIGHT = 26;

export function LyricsEditor({ song, saveAction, deleteAction }: LyricsEditorProps) {
  const [title, setTitle] = useState(song?.title ?? "");
  const [lyrics, setLyrics] = useState(song?.lyrics ?? "");
  const [pageIndex, setPageIndex] = useState(0);
  const [tabs, setTabs] = useState<SongTabs>(song?.tabs ?? EMPTY_SONG_TABS);
  const [dragState, setDragState] = useState<DragState | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement | null>(null);
  const screenRef = useRef<HTMLDivElement | null>(null);

  const saveFormId = song ? `song-save-${song.id}` : "song-save-new";
  const pages = useMemo(() => splitByPageMarkers(lyrics), [lyrics]);
  const safePageIndex = Math.min(pageIndex, Math.max(pages.length - 1, 0));
  const currentPage = pages[safePageIndex] ?? "";
  const currentPageLineCount = currentPage ? currentPage.split(/\r?\n/).length : 0;
  const isDensePage = currentPageLineCount > 28 || currentPage.length > 850;

  useEffect(() => {
    setPageIndex(0);
  }, [lyrics]);

  useEffect(() => {
    setTabs((current) => reconcileTabs(current, pages.length));
  }, [pages.length]);

  const placementsForPage = useMemo(
    () => placementsByNote(getPagePlacements(tabs, safePageIndex)),
    [tabs, safePageIndex],
  );

  const tabsJson = useMemo(() => JSON.stringify(tabs), [tabs]);

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

  const updateNotePosition = useCallback(
    (note: TabNote, normalizedX: number, normalizedY: number) => {
      setTabs((current) => updateTabPlacement(current, safePageIndex, note, normalizedX, normalizedY));
    },
    [safePageIndex],
  );

  function handlePointerDown(event: ReactPointerEvent<HTMLDivElement>, note: TabNote) {
    const screen = screenRef.current;
    const target = event.currentTarget;

    if (!screen) {
      return;
    }

    const targetRect = target.getBoundingClientRect();
    target.setPointerCapture(event.pointerId);
    setDragState({
      note,
      pointerId: event.pointerId,
      offsetX: event.clientX - targetRect.left,
      offsetY: event.clientY - targetRect.top,
    });
    event.preventDefault();
  }

  function handlePointerMove(event: ReactPointerEvent<HTMLDivElement>) {
    const screen = screenRef.current;

    if (!dragState || !screen || dragState.pointerId !== event.pointerId) {
      return;
    }

    const screenRect = screen.getBoundingClientRect();
    const localX = event.clientX - screenRect.left - dragState.offsetX;
    const localY = event.clientY - screenRect.top - dragState.offsetY;
    const maxX = Math.max(screenRect.width - PILL_WIDTH, 1);
    const maxY = Math.max(screenRect.height - PILL_HEIGHT, 1);
    const clampedX = clamp(localX, 0, maxX);
    const clampedY = clamp(localY, 0, maxY);
    const normalizedX = clampedX / Math.max(screenRect.width, 1);
    const normalizedY = clampedY / Math.max(screenRect.height, 1);

    updateNotePosition(dragState.note, normalizedX, normalizedY);
  }

  function handlePointerUp(event: ReactPointerEvent<HTMLDivElement>) {
    if (!dragState || dragState.pointerId !== event.pointerId) {
      return;
    }

    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }

    setDragState(null);
  }

  return (
    <div className="editor-grid">
      <section className="panel">
        <form action={saveAction} id={saveFormId}>
          <input
            aria-label="Song title"
            className="title-input"
            id="title"
            name="title"
            onChange={(event) => setTitle(event.target.value)}
            placeholder="Untitled song"
            required
            value={title}
          />

          <input name="sortOrder" type="hidden" value={song?.sortOrder ?? 0} />
          <input name="startsOn" type="hidden" value={song?.startsOn ?? ""} />
          <input name="tabs" type="hidden" value={tabsJson} />

          <div className="field-stack">
            <div className="lyrics-section-heading">
              <label htmlFor="lyrics">Lyrics</label>
              <span className="muted lyrics-section-help">
                Use cues, page breaks, and the Tabs panel to shape each page for the iPhone stage view.
              </span>
            </div>
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
        <section className="panel">
          <div className="eyebrow">iPhone 16 Pro simulator</div>
          <h2 className="simulator-title">{title || "Untitled song"}</h2>

          <div className="tabs-section-heading">
            <h3 className="tabs-subtitle">Tabs</h3>
            <span className="muted tabs-help">
              Drag any note pill onto the screen to mark it for page {safePageIndex + 1}.
            </span>
          </div>

          <div className="phone-frame">
            <div
              className="phone-screen"
              onPointerMove={handlePointerMove}
              onPointerUp={handlePointerUp}
              onPointerCancel={handlePointerUp}
              ref={screenRef}
            >
              <div
                className="simulated-lyrics"
                dangerouslySetInnerHTML={{ __html: renderInlineMarkers(currentPage) }}
              />
              {TAB_NOTES.map((note) => {
                const placement = placementsForPage.get(note);
                const style: CSSProperties = placement
                  ? {
                      left: `${placement.x * 100}%`,
                      top: `${placement.y * 100}%`,
                    }
                  : defaultPillStyle(note);
                const isDragging = dragState?.note === note;

                return (
                  <div
                    aria-label={`Note ${note}`}
                    className={`tab-pill${isDragging ? " dragging" : ""}`}
                    key={note}
                    onPointerDown={(event) => handlePointerDown(event, note)}
                    role="button"
                    style={style}
                  >
                    {note}
                  </div>
                );
              })}
              <div className="simulator-page-count">
                Page {Math.min(safePageIndex + 1, pages.length)} / {pages.length}
              </div>
            </div>
          </div>

          <div className="page-controls">
            <button
              className="button secondary"
              disabled={safePageIndex === 0}
              onClick={() => setPageIndex((value) => Math.max(0, value - 1))}
              type="button"
            >
              Previous
            </button>
            <button
              className="button secondary"
              disabled={safePageIndex >= pages.length - 1}
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

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function placementsByNote(placements: TabPlacement[]): Map<TabNote, TabPlacement> {
  const map = new Map<TabNote, TabPlacement>();

  for (const placement of placements) {
    map.set(placement.note, placement);
  }

  return map;
}

function getPagePlacements(tabs: SongTabs, pageIndex: number): TabPlacement[] {
  return tabs.pages.find((page) => page.pageIndex === pageIndex)?.notes ?? [];
}

function reconcileTabs(tabs: SongTabs, pageCount: number): SongTabs {
  if (pageCount <= 0) {
    if (tabs.pages.length === 0) {
      return tabs;
    }

    return { version: 1, pages: [] };
  }

  const filtered = tabs.pages.filter((page) => page.pageIndex < pageCount);
  const isUnchanged =
    filtered.length === tabs.pages.length &&
    filtered.every((page, index) => page === tabs.pages[index]);

  if (isUnchanged) {
    return tabs;
  }

  return { version: 1, pages: filtered };
}

function updateTabPlacement(
  tabs: SongTabs,
  pageIndex: number,
  note: TabNote,
  x: number,
  y: number,
): SongTabs {
  const existingPageIndex = tabs.pages.findIndex((page) => page.pageIndex === pageIndex);

  let nextPages: TabPage[];

  if (existingPageIndex === -1) {
    const newPage: TabPage = {
      pageIndex,
      notes: [{ note, x, y }],
    };
    nextPages = [...tabs.pages, newPage].sort((a, b) => a.pageIndex - b.pageIndex);
  } else {
    const targetPage = tabs.pages[existingPageIndex];
    const existingNoteIndex = targetPage.notes.findIndex((placement) => placement.note === note);
    let nextNotes: TabPlacement[];

    if (existingNoteIndex === -1) {
      nextNotes = [...targetPage.notes, { note, x, y }];
    } else {
      nextNotes = targetPage.notes.map((placement, index) =>
        index === existingNoteIndex ? { note, x, y } : placement,
      );
    }

    nextPages = tabs.pages.map((page, index) =>
      index === existingPageIndex ? { ...page, notes: nextNotes } : page,
    );
  }

  return { version: 1, pages: nextPages };
}

function defaultPillStyle(note: TabNote): CSSProperties {
  const index = TAB_NOTES.indexOf(note);
  const columns = 6;
  const column = index % columns;
  const row = Math.floor(index / columns);
  const left = 4 + column * 15;
  const top = 4 + row * 7;

  return {
    left: `${left}%`,
    top: `${top}%`,
  };
}
