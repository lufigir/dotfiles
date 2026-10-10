import "server-only";
import type { OrderDTO } from "@/data/orders/orders.dto";

export async function findOrder(id: string): Promise<OrderDTO> {
  return { id };
}
