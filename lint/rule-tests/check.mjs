/**
 * ¿Las reglas siguen mordiendo?
 *
 * Un config de lint es la única parte ejecutable de la arquitectura, y también la
 * única que puede dejar de funcionar sin que nada se ponga rojo. Una regla que
 * desaparece de oxlint, un plugin que deja de cargar, una negación `!` que cambia de
 * semántica: el resultado es siempre el mismo, un `oxlint` que sale con cero errores
 * y una frontera que ya no existe. Cero errores es exactamente lo que esperabas ver,
 * así que nadie se entera.
 *
 * Esto invierte la prueba. `fixtures/` es código que DEBE fallar, y cada línea marcada
 * con `CLEAN:` es código que NO debe reportar nada. El fixture es la especificación.
 *
 *     node lint/rule-tests/check.mjs
 *
 * Córrelo después de actualizar oxlint, después de re-vendorizar anti-slop, y en un
 * proyecto que ya copió el preset, después de adaptar la tabla de boundaries: es lo
 * que distingue una negación que reabre de una que se come la regla entera.
 *
 * Monta un proyecto de verdad en un temporal para correr. No es ceremonia: los globs
 * de `overrides` y los `specifier` de `jsPlugins` resuelven contra el DIRECTORIO DEL
 * CONFIG, así que el preset solo se comporta como se va a comportar cuando el config
 * está en la raíz con `tools/` al lado. Probarlo en su sitio probaría otra cosa.
 */

import { execFileSync } from "node:child_process";
import {
  cpSync,
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

/**
 * La raíz es donde vive `oxlint.config.ts`, y se busca subiendo. Así el mismo archivo
 * funciona en dos sitios: dentro del preset en dotfiles, y copiado dentro de un
 * proyecto bajo `tools/oxlint/rule-tests/`. Sin esto habría dos copias divergiendo.
 */
const root = findUp("oxlint.config.ts");
const modules = findUp(join("node_modules", "oxlint", "bin", "oxlint"));

function findUp(relative) {
  let directory = here;

  while (true) {
    if (existsSync(join(directory, relative))) return directory;

    const parent = dirname(directory);
    if (parent === directory) {
      console.error(
        `Could not find \`${relative}\` walking up from \`${here}\`.\n` +
          "Run the verifier from a repo that already has the preset copied into its root.",
      );
      process.exit(1);
    }

    directory = parent;
  }
}

/**
 * Cuántas veces tiene que reportar cada regla. Es un mínimo, no una igualdad: que una
 * regla reporte de más es ruido, se ve en el diff y se discute. Que reporte de menos
 * es la frontera perdida, que es el fallo silencioso que esto persigue.
 */
const EXPECTED = [
  ["evidence.fixture.ts", "no-chained-type-assertions", 1],
  ["evidence.fixture.ts", "require-safety-comment-for-type-assertion", 2],
  ["evidence.fixture.ts", "no-unknown-parameters", 1],
  ["evidence.fixture.ts", "no-unknown-returns", 1],
  ["evidence.fixture.ts", "no-known-value-widening", 1],
  ["evidence.fixture.ts", "no-unknown-type-aliases", 1],
  ["evidence.fixture.ts", "no-unsafe-dictionary-type", 1],
  ["evidence.fixture.ts", "no-runtime-typeof", 1],
  ["evidence.fixture.ts", "no-conditional-empty-object-spread", 1],

  // Las tres formas en que una clase literal llega a un componente, template
  // literal incluido.
  ["colors.fixture.tsx", "no-literal-colors", 3],

  // La frontera, y la policy que no puede tocar el framework.
  ["boundaries.fixture.ts", "no-restricted-imports", 1],
  ["orders.policy.ts", "no-restricted-imports", 1],
];

// Fuera del repo, en el temporal del sistema. Dentro no sirve: oxlint respeta
// `.gitignore` y `--no-ignore` no lo anula, así que un stage ignorado por git no
// tendría un solo archivo que lintear, y uno no ignorado acabaría en un commit el día
// que una corrida se muera a medias.
const stage = mkdtempSync(join(tmpdir(), "lint-preset-"));

try {
  // El config hace `import { defineConfig } from "oxlint"`, así que necesita un
  // `node_modules` a mano. Una junction en lugar de una copia: instantánea, y en
  // Windows no pide privilegios de administrador.
  symlinkSync(join(modules, "node_modules"), join(stage, "node_modules"), "junction");

  cpSync(join(root, "tools"), join(stage, "tools"), { recursive: true });
  cpSync(join(root, "oxlint.config.ts"), join(stage, "oxlint.config.ts"));
  cpSync(join(here, "fixtures"), stage, { recursive: true });

  // El config `.ts` no carga sin esto, y `@/*` tiene que resolver para que las
  // reglas type-aware vean los fixtures como un proyecto y no como archivos sueltos.
  writeFileSync(
    join(stage, "package.json"),
    JSON.stringify({ name: "lint-preset-stage", private: true, type: "module" }, null, 2),
  );
  writeFileSync(
    join(stage, "tsconfig.json"),
    JSON.stringify(
      {
        compilerOptions: {
          strict: true,
          target: "esnext",
          module: "preserve",
          moduleResolution: "bundler",
          jsx: "preserve",
          baseUrl: ".",
          paths: { "@/*": ["./*"] },
        },
      },
      null,
      2,
    ),
  );

  const raw = runOxlint(stage);
  const diagnostics = parse(raw);
  const failures = [...missingRules(diagnostics), ...noisyOnCleanLines(diagnostics)];

  if (failures.length > 0) {
    console.error(`\nRules stopped biting (${failures.length}):\n`);
    for (const failure of failures) console.error(`  - ${failure}`);
    console.error(
      "\nDo not edit `fixtures/` to make this pass: the fixture is the specification.\n" +
        "Fix the config, the plugin, or the oxlint version.\n",
    );
    process.exit(1);
  }

  console.log(`${EXPECTED.length} rules bite, and the lines marked CLEAN are still clean.`);
} finally {
  rmSync(stage, { recursive: true, force: true });
}

function runOxlint(cwd) {
  // El bin de oxlint es un script de Node, así que se invoca directo en vez de por
  // `npx`: sin shell, sin resolver un `.cmd` en Windows, sin el aviso de Node sobre
  // pasar argumentos a través de un shell.
  const bin = join(modules, "node_modules", "oxlint", "bin", "oxlint");

  try {
    // Sale con código distinto de cero por diseño: el fixture está lleno de
    // errores. Lo que importa es el JSON.
    return execFileSync(
      process.execPath,
      [bin, "--type-aware", "-c", "oxlint.config.ts", "-f", "json", "."],
      { cwd, encoding: "utf8" },
    );
  } catch (error) {
    if (typeof error.stdout === "string" && error.stdout.length > 0) return error.stdout;
    throw error;
  }
}

function parse(raw) {
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : (parsed.diagnostics ?? []);
  } catch {
    console.error("oxlint did not return JSON. Raw output:\n");
    console.error(raw);
    process.exit(1);
  }
}

/** `anti-slop(no-unknown-returns)` y `eslint(no-restricted-imports)` -> el nombre pelado. */
function ruleOf(diagnostic) {
  return String(diagnostic.code ?? "").replace(/^.*\(|\)$/g, "");
}

function fileOf(diagnostic) {
  return String(diagnostic.filename ?? "").replaceAll("\\", "/");
}

function lineOf(diagnostic) {
  return diagnostic.labels?.[0]?.span?.line ?? -1;
}

function* missingRules(diagnostics) {
  for (const [file, rule, least] of EXPECTED) {
    const hits = diagnostics.filter((d) => fileOf(d).endsWith(file) && ruleOf(d) === rule);
    if (hits.length < least) {
      yield `${file}: expected at least ${least} of \`${rule}\`, got ${hits.length}. The rule vanished, fell out of the config, or its plugin failed to load.`;
    }
  }
}

/**
 * Lo que NO puede reportar. Cada `CLEAN:` en un fixture es una afirmación de que esa
 * línea es código correcto, y la razón va escrita al lado. Si una regla empieza a
 * marcarla, se volvió ruidosa, o una negación dejó de reabrir lo que debía, que es la
 * forma en que una tabla de boundaries pasa a denegar de más sin que nadie lo note.
 */
function* noisyOnCleanLines(diagnostics) {
  const files = [...new Set(EXPECTED.map(([file]) => file))];

  for (const file of files) {
    const path = findFixture(file);
    if (path === undefined) continue;

    const lines = readFileSync(path, "utf8").split(/\r?\n/);

    for (const [index, text] of lines.entries()) {
      if (!text.includes("CLEAN:")) continue;

      const line = index + 1;
      const hit = diagnostics.find((d) => fileOf(d).endsWith(file) && lineOf(d) === line);

      if (hit !== undefined) {
        const why = text.slice(text.indexOf("CLEAN:") + "CLEAN:".length).trim();
        yield `${file}:${line}: \`${ruleOf(hit)}\` reported on a line marked clean. ${why}`;
      }
    }
  }
}

function findFixture(file) {
  const candidates = [
    join(here, "fixtures", file),
    join(here, "fixtures", "app", file),
    join(here, "fixtures", "data", file),
  ];
  return candidates.find((path) => {
    try {
      readFileSync(path);
      return true;
    } catch {
      return false;
    }
  });
}
