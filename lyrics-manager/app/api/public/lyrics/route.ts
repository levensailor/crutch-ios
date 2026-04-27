import { NextRequest, NextResponse } from "next/server";
import { getPublicLyricsPayload } from "@/lib/songs";

export async function GET(request: NextRequest) {
  const payload = await getPublicLyricsPayload();
  const eTag = `"lyrics-${payload.checksum}"`;

  if (request.headers.get("if-none-match") === eTag) {
    return new Response(null, {
      status: 304,
      headers: {
        ETag: eTag,
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=3600",
      },
    });
  }

  return NextResponse.json(payload, {
    headers: {
      ETag: eTag,
      "Cache-Control": "public, s-maxage=300, stale-while-revalidate=3600",
    },
  });
}
