// incrementa el contador
export function next(value: number): number {
  /* devuelve el siguiente */
  return value + 1;
}

// oxlint-disable-next-line no-console -- CLEAN: una directiva de lint pasa
console.log(next(1));
