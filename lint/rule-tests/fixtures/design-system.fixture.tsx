// `@shadcn/lint`, una vez por regla. Lee `components.json`, el theme de
// `app/globals.css` y las variantes `cva` de `components/ui/button.tsx`, así que
// este fixture solo se comporta como en un proyecto real con esos tres al lado.

import { Button } from "@/components/ui/button";

const tone = "primary";

export const RawColor = () => <div className="bg-blue-500" />;

export const Restyled = () => <Button className="p-4">Save</Button>;

export const Arbitrary = () => <div className="p-[13px]" />;

export const Inline = () => <div style={{ color: "red" }} />;

export const Unknown = () => <div className="rounded-huge" />;

export const Dynamic = () => <Button className={`bg-${tone}`}>Save</Button>;

export const Tokens = () => <div className="bg-primary text-muted-foreground rounded-lg p-4" />; // CLEAN: tokens del theme y la escala de spacing, que es justo lo que las reglas piden usar.

export const Placed = () => (
  <Button size="lg" className="mt-4">
    Save
  </Button>
); // CLEAN: una variante declarada y margen, que `allow: ["layout"]` deja a la página.
