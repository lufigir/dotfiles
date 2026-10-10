import { defineConfig } from "oxlint";

/**
 * El único linter del proyecto. No hay `eslint.config.mjs`.
 *
 * Cuatro familias, que fallan distinto y se configuran distinto:
 *
 *   Boundaries     ¿puede este archivo importar aquel?       -> `no-restricted-imports`
 *   Evidencia      ¿este código prueba lo que afirma?        -> el plugin `anti-slop`
 *   Design system  ¿usa los tokens y variantes que existen?  -> `@shadcn/lint`
 *   Framework      ¿uso el framework como funciona?          -> `nextjs`, `react`, `jsx-a11y`
 *
 * Y las reglas de la casa (`tools/oxlint/house/`), que cierran la frontera
 * servidor/cliente donde ningún plugin publicado llega.
 *
 * Un proyecto con solo la última familia, que es lo que deja el CLI del framework,
 * tiene un linter que formatea y nada que defienda la arquitectura.
 *
 * Todo a `error`. Una regla en `warn` es una regla que se viola para siempre: los
 * avisos se acumulan, la salida se vuelve ruido y entonces nadie la lee, incluido el
 * agente, que ve un muro de avisos preexistentes y concluye razonablemente que el
 * suyo es normal.
 *
 * Requisitos del entorno, los dos verificados contra oxlint 1.87.0:
 *   - `package.json` necesita `"type": "module"`, o el config `.ts` no carga.
 *   - `--type-aware` necesita `oxlint-tsgolint` instalado.
 */
/**
 * La frontera entre módulos de `data/`. Un módulo puede leer de otro (su DTO, su
 * DAL, su policy): un lookup compartido como `geo.dal` o la identidad de
 * `auth.dal` es reutilización, no erosión. Lo que no puede es:
 *
 *   - Importar las `*.actions` de otro módulo. Una action es un endpoint, la
 *     puerta de entrada de su módulo; una action que llama a otra encadena dos
 *     endpoints públicos y sus dos validaciones.
 *   - Escapar con `../`. Lo que cruza módulos va por `@/data/...`, para que el
 *     acoplamiento se vea en un grep y que esta misma regla lo alcance.
 *
 * Lo que impide la dependencia mutua (`orders` usa `billing` y `billing` usa
 * `orders`) es `import/no-cycle`, no esto.
 *
 * Ojo con `regex` en vez de `group`: oxlint 1.87 acepta la clave y la ignora en
 * silencio, así que la regla parece configurada y no reporta nada.
 */
const CROSS_MODULE = {
  group: ["@/data/*/*.actions", "../**"],
  message:
    "A module reaches another one through @/data/<module>/..., and never through its *.actions: an action is a public endpoint, the entry point of its own module. Compose in your own action instead.",
};

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

  // Declarar `plugins` REEMPLAZA el set por defecto (`eslint`, `typescript`,
  // `unicorn`, `oxc`), no lo amplía. Sin `unicorn` y `oxc` en esta lista se
  // pierden en silencio sus reglas de `correctness`: `no-new-array`,
  // `missing-throw`, `const-comparisons` y una veintena más.
  plugins: [
    "import",
    "typescript",
    "react",
    "nextjs",
    "jsx-a11y",
    "unicorn",
    "oxc",
    "promise",
    "node",
  ],

  // El suelo. Todo lo que es directamente incorrecto o inútil. Ojo: la categoría
  // NO trae todo lo que suena a corrección. `react/rules-of-hooks` es `pedantic`
  // y `switch-exhaustiveness-check` también; por eso van abajo por nombre.
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
    // Dependencia, no vendorizado como anti-slop: tiene releases y semver.
    "@shadcn/lint",
    { name: "house", specifier: "./tools/oxlint/house/index.ts" },
  ],

  rules: {
    "import/no-cycle": "error",
    "typescript/no-floating-promises": "error",
    // --- Seguridad --------------------------------------------------------------
    //
    // Sinks donde un dato ajeno se vuelve código. El lint no prueba que la
    // autorización sea correcta (eso es revisión); solo cierra estas puertas.
    // `iframe-missing-sandbox` atrapó un XSS real en vicerrectoria-app: un blob
    // hereda el origen de la app. Un uso legítimo de `no-danger` (un script
    // constante, p. ej.) va con disable y un comentario SAFETY.
    "no-eval": "error",
    "no-new-func": "error",
    "no-script-url": "error",
    "react/no-danger": "error",
    "react/iframe-missing-sandbox": "error",
    "react/jsx-no-script-url": "error",
    "react/jsx-no-target-blank": "error",
    // Un `postMessage` sin origen destino entrega el mensaje a cualquier ventana.
    "unicorn/require-post-message-target-origin": "error",
    // `Math.random` no es criptográfico. Un token, un id de invitación o un
    // nonce que se pueda adivinar es una cuenta tomada.
    "no-restricted-properties": [
      "error",
      {
        object: "Math",
        property: "random",
        message:
          "Math.random is predictable. Use crypto.randomUUID() or crypto.getRandomValues() for anything an attacker could guess; for animation jitter, a disable comment that says so.",
      },
    ],
    // Los secretos salen del objeto `env` validado, nunca de `process.env`: un
    // typo devuelve `undefined` para siempre. Ver `operations.md`. Los archivos
    // que validan el entorno y los configs de herramientas quedan exentos abajo.
    "node/no-process-env": "error",

    // --- React: las reglas de hooks que `correctness` no trae ------------------
    //
    // `rules-of-hooks` es `pedantic` en oxlint, así que la categoría no la
    // enciende. Las demás son las del React Compiler que viven en `suspicious` y
    // `perf`: dependencias de efectos y memos que sobran o faltan, estado
    // derivado en un efecto (un render de más y un frame inconsistente),
    // componentes definidos dentro de otro (remontan en cada render).
    "react/rules-of-hooks": "error",
    "react/hooks": "error",
    "react/exhaustive-effect-dependencies": "error",
    "react/memo-dependencies": "error",
    "react/no-deriving-state-in-effects": "error",
    "react/no-unstable-nested-components": "error",
    "react/jsx-no-constructed-context-values": "error",
    "react/no-array-index-key": "error",
    "react/button-has-type": "error",
    "react/jsx-no-useless-fragment": "error",

    // --- Tipos: lo que solo el chequeador ve ------------------------------------
    //
    // `switch-exhaustiveness-check` exige nombrar cada miembro de la unión, aunque
    // haya `default`. En las apps donde se midió, los dos casos que marcó
    // (`"dismissed"`, `"text"`) eran omisiones a propósito; lo que la regla
    // evita es que un miembro que se agregue mañana caiga igual de callado.
    // `checksVoidReturn.attributes: false` deja `onClick={async () => ...}`, que
    // React maneja; lo que sigue prohibido es pasar una promesa donde nadie la
    // espera, como un `forEach(async ...)`.
    "typescript/switch-exhaustiveness-check": "error",
    "typescript/no-misused-promises": ["error", { checksVoidReturn: { attributes: false } }],
    "typescript/only-throw-error": "error",
    "typescript/prefer-promise-reject-errors": "error",
    "typescript/no-deprecated": "error",
    "typescript/no-base-to-string": "error",
    "typescript/consistent-type-imports": "error",
    "promise/no-multiple-resolved": "error",
    "promise/no-promise-in-callback": "error",

    // --- Buenas prácticas ---------------------------------------------------------
    //
    // `no-await-in-loop` es el N+1 de `resource-budget.md` con firma sintáctica:
    // una consulta por vuelta. Si el orden importa de verdad (paginación, rate
    // limit), un disable con la razón; si no, `Promise.all` o una sola consulta.
    // `no-console` porque `console.log` no es logging (`operations.md`); el
    // logger queda exento abajo. `no-array-sort` porque `sort` muta el arreglo
    // que recibiste: `toSorted`.
    eqeqeq: ["error", "always", { null: "ignore" }],
    "no-shadow": "error",
    "preserve-caught-error": "error",
    "no-await-in-loop": "error",
    "no-console": "error",
    "unicorn/no-array-sort": "error",
    "oxc/no-accumulating-spread": "error",
    "oxc/no-map-spread": "error",

    // --- Escala: límites de tamaño ------------------------------------------------
    //
    // No miden calidad, miden cuándo un archivo dejó de tener una sola razón para
    // cambiar. Un módulo de 400 líneas o una función con complejidad 15 no es un
    // error en sí; es el punto en que partirlo cuesta menos que seguir leyéndolo.
    // `no-barrel-file` con umbral 0: un `export *` hace que importar una cosa
    // cargue el módulo entero, y en dev de Next eso es tiempo de compilación.
    "max-lines": ["error", { max: 400, skipBlankLines: true, skipComments: true }],
    complexity: ["error", 15],
    "max-depth": ["error", 4],
    "max-params": ["error", 4],
    "import/max-dependencies": ["error", { max: 20 }],
    "oxc/no-barrel-file": ["error", { threshold: 0 }],

    // --- Estrictas: apagadas por decisión, no por olvido --------------------------
    //
    // Medidas en tres apps reales, cada una da entre 100 y 320 errores. Son la
    // misma postura que anti-slop (el código prueba lo que afirma), llevada al
    // flujo de control. Enciéndelas en un proyecto nuevo, desde el primer día:
    // adoptarlas después es una migración.
    //
    //   "typescript/strict-boolean-expressions"  `if (count)` con count = 0.
    //   "typescript/no-unnecessary-condition"    ramas que los tipos dicen muertas.
    //   "typescript/no-unsafe-type-assertion"    `as` que estrecha sin probar.
    //   "typescript/no-non-null-assertion"       `!` es un `as` disfrazado.
    //   "max-lines-per-function"                 80 líneas; choca con componentes JSX.

    // --- Casa ---------------------------------------------------------------------
    //
    // `no-server-code-in-client`: un `"use client"` que importa un DAL, un
    // cliente de base de datos o el env del servidor lo manda al bundle.
    // `action-asserts-identity`: una server action es un POST público; su primera
    // sentencia llama a `requireUser()` o a `XDAL.create()`. Si el proyecto usa
    // otros nombres, `identity: ["^getSession$"]`. `dal-imports-server-only` va
    // en el override de `*.dal.ts`.
    "house/no-server-code-in-client": "error",
    "house/action-asserts-identity": "error",

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
    //                                          Jest y exige seams reales.
    //                                          Enciéndela cuando haya tests.
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

    // --- Design system: @shadcn/lint ------------------------------------------
    //
    // Lee `components.json`, el theme de Tailwind v4 y las variantes `cva` de cada
    // componente, y cada error dice qué usar en vez de lo que se escribió: la
    // variante, el token más cercano o el valor de la escala. No hace falta
    // shadcn/ui; sin `components.json` busca `components/ui` y la hoja que importa
    // Tailwind.
    //
    // `allow: ["layout"]` deja a la página decidir dónde va un componente (margen,
    // ancho, grid) y a la variante decidir cómo se ve. Para abrir más en un
    // componente concreto, un contrato: `contracts: [{ pattern: "^CardTitle$",
    // allow: ["layout", "typography"] }]`.
    "shadcn/no-restyle": ["error", { allow: ["layout"] }],
    "shadcn/no-raw-colors": "error",
    "shadcn/no-arbitrary-values": ["error", { allow: ["layout"] }],
    "shadcn/no-inline-styles": "error",
    "shadcn/no-unknown-classes": "error",
    "shadcn/require-static-classes": "error",
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
              CROSS_MODULE,
            ],
          },
        ],
      },
    },

    {
      // Frontera entre módulos. Un `*.dal.ts` sostiene el cliente de base de
      // datos, así que no hereda el bloque de arriba; lo único que se le cierra es
      // lo que acopla módulos.
      files: ["data/**/*.dal.ts"],
      rules: {
        "no-restricted-imports": ["error", { patterns: [CROSS_MODULE] }],
        // Sin el marcador, un import desde un componente cliente manda las
        // consultas y los secretos al navegador, y el build no se queja.
        "house/dal-imports-server-only": "error",
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
                  "../**",
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
      //
      // Salvo tres de @shadcn/lint: un componente se estiliza a sí mismo y llama
      // a sus propias variantes, así que las reglas de quien lo USA sobran aquí,
      // pero un color crudo, un `style` inline o una clase que Tailwind no genera
      // están mal también dentro del componente.
      files: ["components/ui/**"],
      rules: {
        "shadcn/no-restyle": "off",
        "shadcn/no-arbitrary-values": "off",
        "shadcn/require-static-classes": "off",
        "typescript/no-floating-promises": "off",
        // Las de React, tamaño y casa que el CLI no cumple: `calendar.tsx` de
        // shadcn define componentes dentro de otro, y eso no se arregla aquí.
        "react/no-unstable-nested-components": "off",
        "react/no-array-index-key": "off",
        complexity: "off",
        "max-lines": "off",
        "oxc/no-barrel-file": "off",
      },
    },

    {
      // Donde el entorno se valida y donde las herramientas leen su config. Es
      // la única puerta a `process.env`; el resto importa el objeto validado.
      files: ["lib/env*.ts", "*.config.{ts,mts,js,mjs}", "instrumentation*.ts", "scripts/**"],
      rules: { "node/no-process-env": "off" },
    },

    {
      // El logger es el único que escribe en la consola.
      files: ["lib/log*.ts", "lib/logger/**", "instrumentation*.ts"],
      rules: { "no-console": "off" },
    },

    {
      // Scripts de una sola ejecución: seeds, migraciones de datos, probes.
      // Secuenciales a propósito y con su salida en consola.
      files: ["scripts/**"],
      rules: { "no-console": "off", "no-await-in-loop": "off" },
    },
  ],
});
