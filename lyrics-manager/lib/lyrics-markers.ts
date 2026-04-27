export function splitByPageMarkers(lyrics: string): string[] {
  const text = lyrics.replaceAll("\\n", "\n");

  if (!text) {
    return [""];
  }

  const pages: string[] = [];
  let currentPage: string[] = [];

  for (const line of text.split(/\r?\n/)) {
    const trimmedLine = line.trim();

    if (
      trimmedLine === "#####" ||
      trimmedLine.startsWith("#####") ||
      trimmedLine.endsWith("#####")
    ) {
      if (currentPage.length > 0) {
        pages.push(currentPage.join("\n"));
        currentPage = [];
      }

      continue;
    }

    currentPage.push(line);
  }

  if (currentPage.length > 0) {
    pages.push(currentPage.join("\n"));
  }

  return pages.length > 0 ? pages : [text];
}

export function renderInlineMarkers(text: string): string {
  return text
    .split(/\r?\n/)
    .map((line) =>
      escapeHtml(line)
        .replace(/\*\*([^*]+)\*\*/g, '<mark class="pink">$1</mark>')
        .replace(/~~([^~]+)~~/g, '<mark class="green">$1</mark>')
    )
    .join("\n");
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
