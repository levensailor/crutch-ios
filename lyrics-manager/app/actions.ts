"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createSong, deleteSong, songFormDataToInput, updateSong } from "@/lib/songs";

export async function createSongAction(formData: FormData) {
  const song = await createSong(songFormDataToInput(formData));
  revalidateLyricsPaths(song.id);
  redirect(`/songs/${song.id}`);
}

export async function updateSongAction(id: string, formData: FormData) {
  await updateSong(id, songFormDataToInput(formData));
  revalidateLyricsPaths(id);
  redirect(`/songs/${id}`);
}

export async function deleteSongAction(id: string) {
  await deleteSong(id);
  revalidateLyricsPaths(id);
  redirect("/");
}

function revalidateLyricsPaths(id: string) {
  revalidatePath("/");
  revalidatePath("/api/public/lyrics");
  revalidatePath(`/songs/${id}`);
}
