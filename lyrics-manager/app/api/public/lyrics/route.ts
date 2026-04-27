import { NextRequest, NextResponse } from "next/server";
import { getPublicLyricsPayload } from "@/lib/songs";

export const dynamic = "force-dynamic";
const publicLyricsCacheControl = "public, s-maxage=60, stale-while-revalidate=300";

export async function GET(request: NextRequest) {
  const payload = await getPublicLyricsPayload();
  const eTag = `"lyrics-${payload.version}-${payload.checksum}"`;

  if (request.headers.get("if-none-match") === eTag) {
    return new Response(null, {
      status: 304,
      headers: {
        ETag: eTag,
        "Cache-Control": publicLyricsCacheControl,
      },
    });
  }

  return NextResponse.json(payload, {
    headers: {
      ETag: eTag,
      "Cache-Control": publicLyricsCacheControl,
    },
  });
}
