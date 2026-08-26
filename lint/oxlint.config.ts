import { defineConfig } from "oxlint";

/**
 * El único linter del proyecto. No hay `eslint.config.mjs`.
 *
 * Tres familias, que fallan distinto y se configuran distinto:
 *
 *   Boundaries  ¿puede este archivo importar aquel?   -> `no-restricted-imports`
 *   Evidencia   ¿este código prueba lo que afirma?    -> el plugin `anti-slop`
 *   Framework   ¿uso el framework como funciona?      -> `nextjs`, `react`, `jsx-a11y`
 *
 * Un proyecto con solo la tercera familia, que es lo que deja el CLI del framework,
 * tiene un linter que formatea y nada que defienda la arquitectura.
 *
 * Todo a `error`. Una regla en `warn` es una regla que se viola para siempre: los
 * avisos se acumulan, la salida se vuelve ruido y entonces nadie la lee, incluido el
 * agente, que ve un muro de avisos preexistentes y concluye razonablemente que el
 * suyo es normal.
 *
 * Requisitos del entorno, los dos verificados contra oxlint 1.80.0:
 *   - `package.json` necesita `"type": "module"`, o el config `.ts` no carga.
 *   - `--type-aware` necesita `oxlint-tsgolint` instalado.
 */
export default defineConfig({
  ignorePatterns: [
    // Normalmente lo cubre `.gitignore`, que oxlint respeta. Explícito de todas
    // formas: `rule-tests/check.mjs` monta un proyecto de prueba fuera del repo,
    // donde no hay `.gitignore` que lo tape, y sin esta línea el linter se pondría
    // a auditar el código compilado de sus propias dependencias.
    "node_modules/**",
    // El linter no se linta a sí mismo.
    "tools/oxlint/**",
    // Tooling de agentes: son assets instalados, no código fuente de la app.
    ".agent/**",
    ".agents/**",
    ".claude/**",
    ".codex/**",
    ".cursor/**",
    ".gemini/**",
    ".opencode/**",
    ".windsurf/**",
  ],

  plugins: ["import", "typescript", "react", "nextjs", "jsx-a11y"],

  // El suelo. Todo lo que es directamente incorrecto o inútil.
  categories: { correctness: "error" },

  options: {
    // Necesita el chequeador de tipos, así que es más lento que las reglas que
    // solo miran sintaxis. Se paga solo con `no-floating-promises`: una server
    // action que llama al DAL sin await devuelve un éxito de una escritura que
    // nunca ocurrió, y en serverless esa promesa se descarta entera en vez de
    // llegar tarde. Ese fallo es invisible en review y obvio para el compilador.
    typeAware: true,
  },

  jsPlugins: [
    { name: "anti-slop", specifier: "./tools/oxlint/anti-slop/index.ts" },
    { name: "house", specifier: "./tools/oxlint/house/index.ts" },
  ],

  rules: {
    "import/no-cycle": "error",
    "typescript/no-floating-promises": "error",

    // --- Evidencia: anti-slop -------------------------------------------------
    //
    // El objetivo es un modo de fallo concreto, y es el que más producen los
    // agentes: código que fabrica evidencia. No código incorrecto, sino código
    // que le dice al compilador que comprobó algo que nunca comprobó.
    //
    //   const user = input as object as User    dos aserciones, cero verificación
    //   function handle(input: unknown) {}      el contrato del llamante es "cualquier cosa"
    //   type Metadata = Record<string, unknown> un diccionario que no promete nada
    //
    // Las tres compilan, pasan un review por encima, y mueven un fallo de runtime
    // lejos de su causa.
    "anti-slop/no-chained-type-assertions": "error",
    "anti-slop/no-conditional-empty-object-spread": "error",
    "anti-slop/no-known-value-widening": "error",
    "anti-slop/no-runtime-typeof": "error",
    "anti-slop/no-unknown-parameters": "error",
    "anti-slop/no-unknown-returns": "error",
    "anti-slop/no-unknown-type-aliases": "error",
    "anti-slop/no-unsafe-dictionary-type": "error",
    "anti-slop/no-widen-then-assert": "error",
    "anti-slop/require-safety-comment-for-type-assertion": "error",

    // Las cinco restantes de anti-slop están apagadas por omisión, no por olvido.
    // Cada una es una decisión de diseño fuerte que conviene pelear en código real
    // antes de heredarla. Enciéndelas cuando el proyecto te dé la razón:
    //
    //   "anti-slop/no-object-parameters"       prohíbe el tipo `object` en entradas.
    //                                          Correcta casi siempre; choca con
    //                                          firmas de librerías que lo piden.
    //   "anti-slop/no-module-mocking"          prohíbe mockear módulos en Vitest o
    //                                          Jest y exige seams reales. Es la
    //                                          misma postura que la skill `tdd`;
    //                                          enciéndela cuando haya tests.
    //   "anti-slop/no-reflect-get"             `Reflect.get` en vez de acceso tipado.
    //   "anti-slop/no-reflect-apply"           `Reflect.apply` en vez de llamada tipada.
    //   "anti-slop/no-shape-in-symbol-names"   prohíbe "shape" en nombres. Muy
    //                                          específica del gusto del autor.
    //
    // Y si el proyecto declara `effect` como dependencia directa, registra también
    // el plugin opcional en `jsPlugins`:
    //
    //   { name: "anti-slop-effect", specifier: "./tools/oxlint/anti-slop/effect/index.ts" }
    //   "anti-slop-effect/no-service-constructor-imports": "error"

    // --- Design system --------------------------------------------------------
    "house/no-literal-colors": "error",
  },

  overrides: [
    // ====================================================================
    // Boundaries. Esta es la parte que hay que ADAPTAR por proyecto: solo tu
    // repo conoce sus capas. Lo de abajo es el perfil de app única de
    // `architecture.md` (app/ -> data/ -> lib/), listo para renombrar.
    //
    // Dos detalles deciden si esto funciona de verdad:
    //
    // 1. DENIEGA POR DEFECTO, no por lista. Una regla que prohíbe los cuatro
    //    imports ilegales que se te ocurrieron calla sobre el quinto directorio
    //    que aparezca el mes que viene. Una regla que permite solo lo que la
    //    tabla dice falla en cuanto surge una capa nueva, que es justo cuando
    //    quieres que te pregunten. Por eso cada bloque cierra un grupo entero
    //    y reabre con `!` lo poco que es legal.
    //
    // 2. EL CLIENTE DE BASE DE DATOS ES LA EXCEPCIÓN INTERESANTE. Fluye hacia
    //    arriba a todos por la regla de dependencias, pero solo el DAL puede
    //    LLAMAR al ORM. Si esto se hace mal, el no-negociable "el DAL es el
    //    único camino a la base de datos" queda sin aplicar mientras parece
    //    aplicado.
    // ====================================================================

    {
      // La UI no llega a la base de datos. Cerrar solo los wrappers de
      // `lib/db/` dejaría abierta de par en par la puerta que envuelven, así
      // que el paquete del proveedor se cierra también.
      files: ["app/**/*.{ts,tsx}", "components/**/*.{ts,tsx}"],
      rules: {
        "no-restricted-imports": [
          "error",
          {
            patterns: [
              {
                group: [
                  "@/lib/db/*",
                  "@supabase/*",
                  // El cliente de navegador es la única pieza que la UI
                  // puede sostener, y solo donde el producto suscribe
                  // realtime directamente desde el browser.
                  "!@/lib/db/client",
                ],
                message:
                  "A service-role client, or any other database client, bypasses row-level security or the single door in. Only a *.dal.ts may import one.",
              },
              {
                group: ["@/lib/env.server"],
                message:
                  "Server-side environment variables do not cross into the UI layer. Pass them down as props from a Server Component.",
              },
            ],
          },
        ],
      },
    },

    {
      // Deniega por defecto también dentro de la capa de datos: solo un
      // `*.dal.ts` sostiene un cliente, así que aquí no se reabre nada.
      files: ["data/**/*.ts"],
      excludeFiles: ["data/**/*.dal.ts"],
      rules: {
        "no-restricted-imports": [
          "error",
          {
            patterns: [
              {
                group: ["@/lib/db/*", "@supabase/*"],
                message:
                  "Only *.dal.ts talks to the database. A DTO, a policy or an action that queries breaks the single door in.",
              },
            ],
          },
        ],
      },
    },

    {
      // Una policy es una función pura: recibe lo que juzga y quién pregunta,
      // y devuelve un booleano. Listar lo que NO puede importar era la versión
      // débil, porque dejaba alcanzables `next/*` y todos los `*.dal`. Se
      // cierra todo y se reabren exactamente dos cosas.
      files: ["data/**/*.policy.ts"],
      rules: {
        "no-restricted-imports": [
          "error",
          {
            patterns: [
              {
                group: [
                  "@/data/*/*",
                  "@/lib/*",
                  "@supabase/*",
                  "next/*",
                  "server-only",
                  "!@/data/*/*.dto",
                ],
                message:
                  "A policy is pure: no session, no database, no effects. It may only import types from a *.dto.",
              },
            ],
          },
        ],
      },
    },

    {
      // `lib/` es la capa de abajo y no sube. Lo único que viaja hacia arriba
      // es vocabulario compartido, o sea un tipo de un *.dto. Sin este bloque
      // `lib/` es la única capa del repo sin frontera, y nada impide que un
      // helper importe un DAL y se convierta en la segunda puerta a la base
      // de datos.
      files: ["lib/**/*.ts"],
      excludeFiles: ["lib/db/**"],
      rules: {
        "no-restricted-imports": [
          "error",
          {
            patterns: [
              {
                group: ["@/app/*", "@/components/*", "@/data/*/*", "!@/data/*/*.dto"],
                message:
                  "lib/ is the bottom layer: it does not import from app/, components/ or data/. The only thing that travels upward is a *.dto type.",
              },
            ],
          },
        ],
      },
    },

    {
      // Propiedad del CLI del design system (shadcn y compañía). Editarlo
      // significa perder el cambio en la siguiente actualización, así que
      // queda exento de las reglas de este repo. Se envuelve, no se edita.
      files: ["components/ui/**"],
      rules: {
        "house/no-literal-colors": "off",
        "typescript/no-floating-promises": "off",
      },
    },
  ],
});
