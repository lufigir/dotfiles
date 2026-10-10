// Las reglas de hooks y de React que `correctness` NO trae. Si `rules-of-hooks`
// deja de reportar, la categoría volvió a tragársela y nadie se enteró.
import { createContext, useState } from "react";

const Theme = createContext({ dark: false });

export function Conditional({ ok }: { ok: boolean }) {
  if (ok) {
    const [count] = useState(0);
    return <p>{count}</p>;
  }
  return null;
}

export function TopLevel() {
  const [count] = useState(0); // CLEAN: un hook en el nivel superior es exactamente lo que pide la regla.
  return <p>{count}</p>;
}

export function Nested({ items }: { items: string[] }) {
  function Row({ text }: { text: string }) {
    return <li>{text}</li>;
  }
  return (
    <ul>
      {items.map((text, index) => (
        <Row key={index} text={text} />
      ))}
    </ul>
  );
}

export function Provider({ dark }: { dark: boolean }) {
  return (
    <Theme.Provider value={{ dark }}>
      <button onClick={() => undefined}>Cambiar</button>
    </Theme.Provider>
  );
}
