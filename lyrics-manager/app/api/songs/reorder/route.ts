import { NextResponse } from "next/server";
import { ZodError } from "zod";
import { reorderSongs } from "@/lib/songs";
import { songOrderSchema } from "@/lib/schemas";

export const dynamic = "force-dynamic";

export async function PATCH(request: Request) {
  try {
    const input = songOrderSchema.parse(await request.json());
    const songs = await reorderSongs(input);

    return NextResponse.json({ songs });
  } catch (error) {
    if (error instanceof ZodError) {
      return NextResponse.json(
        { error: "Invalid song order payload.", issues: error.issues },
        { status: 400 }
      );
    }

    return NextResponse.json({ error: "Unable to reorder songs." }, { status: 500 });
  }
}
