import { NextResponse } from "next/server";
import { ZodError } from "zod";
import { updateSongVisibility } from "@/lib/songs";
import { songVisibilitySchema } from "@/lib/schemas";

export const dynamic = "force-dynamic";

export async function PATCH(request: Request) {
  try {
    const input = songVisibilitySchema.parse(await request.json());
    const songs = await updateSongVisibility(input);

    return NextResponse.json({ songs });
  } catch (error) {
    if (error instanceof ZodError) {
      return NextResponse.json(
        { error: "Invalid song visibility payload.", issues: error.issues },
        { status: 400 },
      );
    }

    return NextResponse.json({ error: "Unable to update song visibility." }, { status: 500 });
  }
}
