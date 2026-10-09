// Seguridad: sinks donde un dato ajeno se vuelve código. Si `react` deja de
// cargar como plugin, caen las cuatro de React a la vez.

export function evaluate(source: string): unknown {
  return eval(source);
}

export function compile(source: string): unknown {
  return new Function(source);
}

export const scriptUrl = "javascript:void(0)";

export function Html({ html }: { html: string }) {
  return <div dangerouslySetInnerHTML={{ __html: html }} />;
}

export function Frame({ src }: { src: string }) {
  return <iframe src={src} title="Documento" />;
}

export function SandboxedFrame({ src }: { src: string }) {
  return <iframe src={src} sandbox="" title="Documento" />; // CLEAN: aislado.
}

export function ScriptLink() {
  return <a href="javascript:alert(1)">Abrir</a>;
}

export function External({ href }: { href: string }) {
  return (
    <a href={href} target="_blank">
      Abrir
    </a>
  );
}

export function SafeExternal({ href }: { href: string }) {
  return <a href={href} target="_blank" rel="noreferrer">Abrir</a>; // CLEAN: sin opener.
}
