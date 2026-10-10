"use server";

import { findOrder } from "@/data/orders/orders.dal";
import { requireUser } from "@/data/user/require-user";

// Escribe y devuelve sin preguntar quién llama: un POST abierto a cualquiera.
export async function chargeAnyone(amount: number) {
  return amount;
}

export async function charge(amount: number) { // CLEAN: establece la identidad con `requireUser()`.
  const user = await requireUser();
  return { user, amount };
}

export async function lookup(raw: string) { // CLEAN: valida primero y llama al DAL, que es donde vive la autorización.
  const id = raw.trim();
  if (id === "") return null;
  return findOrder(id);
}
