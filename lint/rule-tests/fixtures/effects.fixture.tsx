// Cada efecto suelto en un componente DEBE reportar house/no-effect-outside-hooks.
import * as React from "react";
import { useEffect } from "react";

export function Clock(): null {
  useEffect(() => undefined, []);
  React.useLayoutEffect(() => undefined, []);
  return null;
}
