import "server-only";

export async function requireUser(): Promise<{ id: string }> {
  return { id: "u1" };
}
