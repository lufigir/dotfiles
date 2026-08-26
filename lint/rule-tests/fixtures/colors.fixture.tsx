// `house/no-literal-colors`, tres veces: string suelto, atributo JSX y template
// literal. El tercero es el que la versión escrita con `no-restricted-syntax` se
// perdía, y es donde acaban las clases en cuanto alguien mete una condición.

const loose = "bg-blue-500 p-4";

export const InAttribute = () => <div className="text-red-600" />;

export const InTemplate = () => <div className={`border-slate-200 ${loose}`} />;

export const Fine = () => <div className="bg-primary text-muted rounded-2xl" />; // CLEAN: la regla empezó a marcar tokens semánticos, que es justo lo que pide usar.
