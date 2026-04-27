import { NextResponse } from "next/server";
import { ZodError } from "zod";
import { createSong, listSongs } from "@/lib/songs";
import { songInputSchema } from "@/lib/schemas";

export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json({ songs: await listSongs() });
}

export async function POST(request: Request) {
  try {
    const input = songInputSchema.parse(await request.json());
    const song = await createSong(input);
    return NextResponse.json({ song }, { status: 201 });
  } catch (error) {
    return errorResponse(error);
  }
}

function errorResponse(error: unknown) {
  if (error instanceof ZodError) {
    return NextResponse.json(
      { error: "Invalid song payload.", issues: error.issues },
      { status: 400 }
    );
  }

  return NextResponse.json({ error: "Unable to process song request." }, { status: 500 });
}
