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

type DragState =
  | {
      kind: "palette";
      note: TabNote;
      pointerId: number;
      clientX: number;
      clientY: number;
    }
  | {
      kind: "placement";
      placementId: string;
      pointerId: number;
      offsetX: number;
      offsetY: number;
      clientX: number;
      clientY: number;
      droppedOff: boolean;
    };

const PILL_WIDTH = 32;
const PILL_HEIGHT = 18;

export function LyricsEditor({ song, saveAction, deleteAction }: LyricsEditorProps) {
  const [title, setTitle] = useState(song?.title ?? "");
  const [lyrics, setLyrics] = useState(song?.lyrics ?? "");
  const [pageIndex, setPageIndex] = useState(0);
  const [tabs, setTabs] = useState<SongTabs>(() => normalizePlacementIds(song?.tabs ?? EMPTY_SONG_TABS));
  const [drag, setDrag] = useState<DragState | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement | null>(null);
  const screenRef = useRef<HTMLDivElement | null>(null);

  const saveFormId = song ? `song-save-${song.id}` : "song-save-new";
  const pages = useMemo(() => splitByPageMarkers(lyrics), [lyrics]);
  const safePageIndex = Math.min(pageIndex, Math.max(pages.length - 1, 0));
  const currentPage = pages[safePageIndex] ?? "";
  const currentPageLineCount = currentPage ? currentPage.split(/\r?\n/).length : 0;
  const isDensePage = currentPageLineCount > 28 || currentPage.length > 850;
  const placementsForPage = useMemo(
    () => getPagePlacements(tabs, safePageIndex),
    [tabs, safePageIndex],
  );
  const tabsJson = useMemo(() => JSON.stringify(tabs), [tabs]);

  useEffect(() => {
    setPageIndex(0);
  }, [lyrics]);

  useEffect(() => {
    setTabs((current) => reconcileTabs(current, pages.length));
  }, [pages.length]);

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

  const screenRectFromCurrent = useCallback((): DOMRect | null => {
    return screenRef.current?.getBoundingClientRect() ?? null;
  }, []);

  function pointIsOverScreen(rect: DOMRect | null, clientX: number, clientY: number): boolean {
    if (!rect) {
      return false;
    }

    return (
      clientX >= rect.left &&
      clientX <= rect.right &&
      clientY >= rect.top &&
      clientY <= rect.bottom
    );
  }

  function placementCenterToNormalized(
    rect: DOMRect,
    centerX: number,
    centerY: number,
  ): { x: number; y: number } {
    const topLeftX = centerX - rect.left - PILL_WIDTH / 2;
    const topLeftY = centerY - rect.top - PILL_HEIGHT / 2;
    const maxX = Math.max(rect.width - PILL_WIDTH, 1);
    const maxY = Math.max(rect.height - PILL_HEIGHT, 1);
    const clampedX = clamp(topLeftX, 0, maxX);
    const clampedY = clamp(topLeftY, 0, maxY);

    return {
      x: clampedX / Math.max(rect.width, 1),
      y: clampedY / Math.max(rect.height, 1),
    };
  }

  function handlePalettePointerDown(event: ReactPointerEvent<HTMLDivElement>, note: TabNote) {
    event.currentTarget.setPointerCapture(event.pointerId);
    setDrag({
      kind: "palette",
      note,
      pointerId: event.pointerId,
      clientX: event.clientX,
      clientY: event.clientY,
    });
    event.preventDefault();
  }

  function handlePalettePointerMove(event: ReactPointerEvent<HTMLDivElement>) {
    if (!drag || drag.kind !== "palette" || drag.pointerId !== event.pointerId) {
      return;
    }

    setDrag({ ...drag, clientX: event.clientX, clientY: event.clientY });
  }

  function handlePalettePointerUp(event: ReactPointerEvent<HTMLDivElement>) {
    if (!drag || drag.kind !== "palette" || drag.pointerId !== event.pointerId) {
      return;
    }

    const rect = screenRectFromCurrent();

    if (pointIsOverScreen(rect, event.clientX, event.clientY) && rect) {
      const normalized = placementCenterToNormalized(rect, event.clientX, event.clientY);
      const newPlacement: TabPlacement = {
        id: createPlacementId(),
        note: drag.note,
        x: normalized.x,
        y: normalized.y,
      };
      setTabs((current) => addPlacement(current, safePageIndex, newPlacement));
    }

    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }

    setDrag(null);
  }

  function handlePlacementPointerDown(
    event: ReactPointerEvent<HTMLDivElement>,
    placement: TabPlacement,
  ) {
    if (!placement.id) {
      return;
    }

    const target = event.currentTarget;
    const targetRect = target.getBoundingClientRect();
    target.setPointerCapture(event.pointerId);
    setDrag({
      kind: "placement",
      placementId: placement.id,
      pointerId: event.pointerId,
      offsetX: event.clientX - targetRect.left,
      offsetY: event.clientY - targetRect.top,
      clientX: event.clientX,
      clientY: event.clientY,
      droppedOff: false,
    });
    event.preventDefault();
  }

  function handlePlacementPointerMove(event: ReactPointerEvent<HTMLDivElement>) {
    if (!drag || drag.kind !== "placement" || drag.pointerId !== event.pointerId) {
      return;
    }

    const rect = screenRectFromCurrent();
    const isOver = pointIsOverScreen(rect, event.clientX, event.clientY);

    setDrag({
      ...drag,
      clientX: event.clientX,
      clientY: event.clientY,
      droppedOff: !isOver,
    });

    if (isOver && rect) {
      const centerX = event.clientX - drag.offsetX + PILL_WIDTH / 2;
      const centerY = event.clientY - drag.offsetY + PILL_HEIGHT / 2;
      const normalized = placementCenterToNormalized(rect, centerX, centerY);
      setTabs((current) =>
        updatePlacement(current, safePageIndex, drag.placementId, normalized.x, normalized.y),
      );
    }
  }

  function handlePlacementPointerUp(event: ReactPointerEvent<HTMLDivElement>) {
    if (!drag || drag.kind !== "placement" || drag.pointerId !== event.pointerId) {
      return;
    }

    const rect = screenRectFromCurrent();

    if (!pointIsOverScreen(rect, event.clientX, event.clientY)) {
      setTabs((current) => removePlacement(current, safePageIndex, drag.placementId));
    }

    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }

    setDrag(null);
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
              Drag a note onto the screen for page {safePageIndex + 1}. Drag a placed note off the
              screen to remove it.
            </span>
          </div>

          <div className="tab-palette" aria-label="Tab note palette">
            {TAB_NOTES.map((note) => (
              <div
                aria-label={`Add ${note} to page ${safePageIndex + 1}`}
                className="tab-pill palette"
                key={note}
                onPointerDown={(event) => handlePalettePointerDown(event, note)}
                onPointerMove={handlePalettePointerMove}
                onPointerUp={handlePalettePointerUp}
                onPointerCancel={handlePalettePointerUp}
                role="button"
              >
                {note}
              </div>
            ))}
          </div>

          <div className="phone-frame">
            <div className="phone-screen" ref={screenRef}>
              <div
                className="simulated-lyrics"
                dangerouslySetInnerHTML={{ __html: renderInlineMarkers(currentPage) }}
              />
              {placementsForPage.map((placement) => {
                const placementId = placement.id;

                if (!placementId) {
                  return null;
                }

                const isDragging =
                  drag?.kind === "placement" && drag.placementId === placementId;
                const style: CSSProperties = {
                  left: `${placement.x * 100}%`,
                  top: `${placement.y * 100}%`,
                };
                const className =
                  "tab-pill placed" + (isDragging ? (drag.droppedOff ? " removing" : " dragging") : "");

                return (
                  <div
                    aria-label={`${placement.note} pill, drag to move or off-screen to remove`}
                    className={className}
                    key={placementId}
                    onPointerDown={(event) => handlePlacementPointerDown(event, placement)}
                    onPointerMove={handlePlacementPointerMove}
                    onPointerUp={handlePlacementPointerUp}
                    onPointerCancel={handlePlacementPointerUp}
                    role="button"
                    style={style}
                  >
                    {placement.note}
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

      {drag?.kind === "palette" ? (
        <div
          aria-hidden="true"
          className="tab-pill ghost"
          style={{
            left: drag.clientX - PILL_WIDTH / 2,
            top: drag.clientY - PILL_HEIGHT / 2,
          }}
        >
          {drag.note}
        </div>
      ) : null}
    </div>
  );
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
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

function addPlacement(tabs: SongTabs, pageIndex: number, placement: TabPlacement): SongTabs {
  const existingPageIndex = tabs.pages.findIndex((page) => page.pageIndex === pageIndex);

  if (existingPageIndex === -1) {
    const newPage: TabPage = { pageIndex, notes: [placement] };
    const nextPages = [...tabs.pages, newPage].sort((a, b) => a.pageIndex - b.pageIndex);
    return { version: 1, pages: nextPages };
  }

  const targetPage = tabs.pages[existingPageIndex];
  const nextNotes = [...targetPage.notes, placement];
  const nextPages = tabs.pages.map((page, index) =>
    index === existingPageIndex ? { ...page, notes: nextNotes } : page,
  );

  return { version: 1, pages: nextPages };
}

function updatePlacement(
  tabs: SongTabs,
  pageIndex: number,
  placementId: string,
  x: number,
  y: number,
): SongTabs {
  const existingPageIndex = tabs.pages.findIndex((page) => page.pageIndex === pageIndex);

  if (existingPageIndex === -1) {
    return tabs;
  }

  const targetPage = tabs.pages[existingPageIndex];
  const nextNotes = targetPage.notes.map((note) =>
    note.id === placementId ? { ...note, x, y } : note,
  );
  const nextPages = tabs.pages.map((page, index) =>
    index === existingPageIndex ? { ...page, notes: nextNotes } : page,
  );

  return { version: 1, pages: nextPages };
}

function removePlacement(tabs: SongTabs, pageIndex: number, placementId: string): SongTabs {
  const existingPageIndex = tabs.pages.findIndex((page) => page.pageIndex === pageIndex);

  if (existingPageIndex === -1) {
    return tabs;
  }

  const targetPage = tabs.pages[existingPageIndex];
  const nextNotes = targetPage.notes.filter((note) => note.id !== placementId);

  if (nextNotes.length === targetPage.notes.length) {
    return tabs;
  }

  const nextPages = tabs.pages.map((page, index) =>
    index === existingPageIndex ? { ...page, notes: nextNotes } : page,
  );

  return { version: 1, pages: nextPages };
}

function normalizePlacementIds(tabs: SongTabs): SongTabs {
  let mutated = false;
  const nextPages = tabs.pages.map((page) => {
    const nextNotes = page.notes.map((note) => {
      if (note.id) {
        return note;
      }

      mutated = true;
      return { ...note, id: createPlacementId() };
    });

    return mutated ? { ...page, notes: nextNotes } : page;
  });

  return mutated ? { version: 1, pages: nextPages } : tabs;
}

function createPlacementId(): string {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }

  return `placement-${Math.random().toString(36).slice(2)}-${Date.now().toString(36)}`;
}
