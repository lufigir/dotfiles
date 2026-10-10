// Buenas prácticas, seguridad de runtime y límites de tamaño.

export function loose(value: number | null): boolean {
  if (value == null) return false; // CLEAN: `== null` cubre null y undefined, y es la única excepción.
  return value == 0;
}

export async function oneByOne(ids: string[], load: (id: string) => Promise<string>) {
  const out: string[] = [];
  for (const id of ids) {
    out.push(await load(id));
  }
  return out;
}

export function debug(value: string): void {
  console.log(value);
}

export function sorted(values: number[]): number[] {
  return values.sort((a, b) => a - b);
}

export const secret = process.env.SECRET;

export const token = Math.random().toString(36);

export function tooMany(a: number, b: number, c: number, d: number, e: number): number {
  return a + b + c + d + e;
}
