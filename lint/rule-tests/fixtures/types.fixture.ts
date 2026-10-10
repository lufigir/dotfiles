// Las reglas type-aware que el preset enciende por nombre, y una regla de cada
// plugin que `plugins` reemplaza (unicorn, oxc, promise). Si una de estas cae,
// el plugin dejó de cargar o salió de la lista.

type Status = "open" | "closed" | "dismissed";

export function label(status: Status): string {
  switch (status) {
    case "open":
      return "Abierta";
    case "closed":
      return "Cerrada";
  }
  return "";
}

export function fail(): never {
  throw "algo salió mal";
}

export function saveAll(ids: string[]): void {
  ids.forEach(async (id) => {
    await Promise.resolve(id);
  });
}

export const slots = new Array(3);

export function inRange(value: number): boolean {
  return value > 10 && value < 5;
}

export const twice = new Promise<number>((resolve) => {
  resolve(1);
  resolve(2);
});
