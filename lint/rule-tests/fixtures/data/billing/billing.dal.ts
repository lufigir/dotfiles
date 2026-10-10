// Frontera entre módulos. Leer el DTO o el DAL de otro módulo es legal; llamar a
// sus actions o escapar con `../` no. Y sin `import "server-only"` arriba, la
// regla de la casa reporta el archivo entero.
import { openOrder } from "@/data/orders/orders.actions";
import type { OrderDTO } from "../orders/orders.dto";
import { resolveNeighborhood } from "@/data/geo/geo.dal"; // CLEAN: leer el DAL de otro módulo es reutilizar un lookup, no erosión.
import { findOrder } from "@/data/orders/orders.dal"; // CLEAN: lo mismo; la negación implícita del grupo no debe alcanzar a los DAL.

export async function invoice(id: string): Promise<OrderDTO> {
  await resolveNeighborhood(id);
  await openOrder(id);
  return findOrder(id);
}
