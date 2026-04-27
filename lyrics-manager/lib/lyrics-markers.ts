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

export function autoAddPageMarkers(
  lyrics: string,
  options: { maxLines?: number; maxCharacters?: number } = {}
): string {
  const maxLines = options.maxLines ?? 28;
  const maxCharacters = options.maxCharacters ?? 850;
  const sourceLines = lyrics
    .replaceAll("\\n", "\n")
    .split(/\r?\n/)
    .filter((line) => !isPageMarkerLine(line));

  const pages: string[][] = [];
  let currentPage: string[] = [];
  let currentCharacters = 0;

  for (const line of sourceLines) {
    const projectedLineCount = currentPage.length + 1;
    const projectedCharacters = currentCharacters + line.length + (currentPage.length > 0 ? 1 : 0);
    const shouldBreak =
      currentPage.length > 0 &&
      (projectedLineCount > maxLines || projectedCharacters > maxCharacters);

    if (shouldBreak) {
      pages.push(trimTrailingBlankLines(currentPage));
      currentPage = [];
      currentCharacters = 0;
    }

    currentPage.push(line);
    currentCharacters += line.length + (currentPage.length > 1 ? 1 : 0);
  }

  if (currentPage.length > 0) {
    pages.push(trimTrailingBlankLines(currentPage));
  }

  return pages
    .filter((page) => page.length > 0)
    .map((page) => page.join("\n").trim())
    .join("\n#####\n");
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

function isPageMarkerLine(line: string): boolean {
  const trimmedLine = line.trim();

  return (
    trimmedLine === "#####" ||
    trimmedLine.startsWith("#####") ||
    trimmedLine.endsWith("#####")
  );
}

function trimTrailingBlankLines(lines: string[]): string[] {
  const nextLines = [...lines];

  while (nextLines.length > 0 && nextLines.at(-1)?.trim() === "") {
    nextLines.pop();
  }

  return nextLines;
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
