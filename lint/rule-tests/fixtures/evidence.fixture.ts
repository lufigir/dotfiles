// Cada línea de este archivo DEBE producir el error anotado a su derecha.
// Si alguna deja de hacerlo, la regla se rompió o se cayó del config, y
// `check.mjs` lo grita. No arregles este archivo: arregla la regla.

type User = { id: string };

declare const payload: string;

// anti-slop/no-chained-type-assertions + require-safety-comment-for-type-assertion
export const chained = payload as unknown as User;

// anti-slop/require-safety-comment-for-type-assertion
export const bare = payload as User;

// anti-slop/no-unknown-parameters
export function acceptsUnknown(value: unknown) {
  return value;
}

// anti-slop/no-unknown-returns + no-known-value-widening
export function returnsUnknown(): unknown {
  return 1;
}

// anti-slop/no-unknown-type-aliases
export type Hidden = unknown;

// anti-slop/no-unsafe-dictionary-type
export const dictionary: Record<string, unknown> = {};

// anti-slop/no-runtime-typeof
export function branchOnTypeof(input: string | number) {
  return typeof input === "string" ? input : String(input);
}

// anti-slop/no-conditional-empty-object-spread
declare const include: boolean;
export const spread = { id: "1", ...(include ? { extra: true } : {}) };
