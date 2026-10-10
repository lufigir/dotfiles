"use server";

import { findOrder } from "@/data/orders/orders.dal";
import { requireUser } from "@/data/user/require-user";

export async function openOrder(id: string) {
  await requireUser();
  return findOrder(id);
}
