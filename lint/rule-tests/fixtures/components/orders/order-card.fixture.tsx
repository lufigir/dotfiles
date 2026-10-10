"use client";

// Un componente cliente que importa un DAL lo manda al bundle del navegador.
import { findOrder } from "@/data/orders/orders.dal";
import type { OrderDTO } from "@/data/orders/orders.dto"; // CLEAN: un tipo se borra al compilar y no viaja.
import { browserClient } from "@/lib/db/client"; // CLEAN: el cliente de navegador es la única pieza de `lib/db` que la UI puede sostener.

export function OrderCard({ order }: { order: OrderDTO }) {
  return (
    <button type="button" onClick={() => void findOrder(order.id)}>
      {String(browserClient)}
    </button>
  );
}
