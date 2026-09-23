// `typescript/no-floating-promises`, la única regla type-aware que el preset
// enciende por su nombre. Si el tsconfig del stage no carga, tsgolint no corre y
// esta regla desaparece sin que nada más falle.

async function save(): Promise<void> {}

export function forgotten(): void {
  save();
}

export async function awaited(): Promise<void> {
  await save(); // CLEAN: una promesa esperada es exactamente lo que la regla pide.
}
