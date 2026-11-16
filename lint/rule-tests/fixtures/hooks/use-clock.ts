import { useEffect } from "react"; // CLEAN: un efecto dentro de un archivo de hook

export function useClock(): void {
  useEffect(() => undefined, []);
}
