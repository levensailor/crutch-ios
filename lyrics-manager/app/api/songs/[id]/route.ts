import { NextResponse } from "next/server";
import { ZodError } from "zod";
import { deleteSong, getSong, updateSong } from "@/lib/songs";
import { songInputSchema } from "@/lib/schemas";

type RouteContext = {
  params: Promise<{
    id: string;
  }>;
};

export async function GET(_request: Request, context: RouteContext) {
  try {
    const { id } = await context.params;
    const song = await getSong(id);

    if (!song) {
      return NextResponse.json({ error: "Song not found." }, { status: 404 });
    }

    return NextResponse.json({ song });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function PUT(request: Request, context: RouteContext) {
  try {
    const { id } = await context.params;
    const input = songInputSchema.parse(await request.json());
    const song = await updateSong(id, input);

    if (!song) {
      return NextResponse.json({ error: "Song not found." }, { status: 404 });
    }

    return NextResponse.json({ song });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(_request: Request, context: RouteContext) {
  try {
    const { id } = await context.params;
    const deleted = await deleteSong(id);

    if (!deleted) {
      return NextResponse.json({ error: "Song not found." }, { status: 404 });
    }

    return NextResponse.json({ deleted: true });
  } catch (error) {
    return errorResponse(error);
  }
}

function errorResponse(error: unknown) {
  if (error instanceof ZodError) {
    return NextResponse.json(
      { error: "Invalid song request.", issues: error.issues },
      { status: 400 }
    );
  }

  return NextResponse.json({ error: "Unable to process song request." }, { status: 500 });
}
