import { defineRule, eslintCompatPlugin } from "@oxlint/plugins";

import type { ESTree } from "@oxlint/plugins";

/**
 * Las reglas de la casa: convenciones de `project-architecture` que tienen firma
 * sintáctica y que ningún plugin publicado revisa. Las tres cierran la frontera
 * servidor/cliente de Next, que es donde un descuido sale más caro: una consulta o un
 * secreto en el bundle del navegador, o un endpoint público sin sesión.
 */

function hasDirective(program: ESTree.Program, directive: string): boolean {
	for (const statement of program.body) {
		if (statement.type !== "ExpressionStatement" || statement.directive === undefined) {
			return false;
		}
		if (statement.directive === directive) return true;
	}
	return false;
}

function stringOptions(options: readonly unknown[] | undefined, key: string): string[] | undefined {
	const option = options?.[0];
	if (typeof option !== "object" || option === null || Array.isArray(option)) return undefined;
	const value: unknown = Reflect.get(option, key);
	if (!Array.isArray(value)) return undefined;
	return value.filter((entry): entry is string => typeof entry === "string");
}

const SERVER_ONLY_DEFAULTS = [
	"\\.dal$",
	"^server-only$",
	"^@/lib/db/(?!client$)",
	"env\\.server$",
];

/** Un archivo `"use client"` no importa código que solo puede vivir en el servidor. */
const noServerCodeInClientRule = defineRule({
	meta: {
		type: "problem",
		docs: {
			description:
				"Disallow importing server-only modules (DAL, database clients, server env) from a \"use client\" file.",
		},
		messages: {
			serverImport:
				"`{{source}}` is server-only and this file is \"use client\": the import ships it to the browser bundle, or fails the build on `server-only`. Call it from a Server Component or a server action and pass the result down.",
		},
		schema: [
			{
				type: "object",
				properties: { patterns: { type: "array", items: { type: "string" } } },
				additionalProperties: false,
			},
		],
	},
	create(context) {
		const patterns = (stringOptions(context.options, "patterns") ?? SERVER_ONLY_DEFAULTS).map(
			(source) => new RegExp(source),
		);
		let isClient = false;

		return {
			Program(node) {
				isClient = hasDirective(node, "use client");
			},
			ImportDeclaration(node) {
				if (!isClient || node.importKind === "type") return;
				const source = node.source.value;
				if (patterns.some((pattern) => pattern.test(source))) {
					context.report({ node, messageId: "serverImport", data: { source } });
				}
			},
		};
	},
});

/** Un `*.dal.ts` importa `server-only`, que convierte la convención en error de build. */
const dalImportsServerOnlyRule = defineRule({
	meta: {
		type: "problem",
		docs: { description: "Require the `server-only` marker in data-access files." },
		messages: {
			missing:
				"A data-access file must `import \"server-only\"` at the top. Without it, one bad import from a client component ships the queries and secrets to the browser.",
		},
		schema: [],
	},
	create(context) {
		return {
			Program(node) {
				const marked = node.body.some(
					(statement) =>
						statement.type === "ImportDeclaration" && statement.source.value === "server-only",
				);
				if (!marked) context.report({ node, messageId: "missing" });
			},
		};
	},
});

const IDENTITY_DEFAULTS = ["^require[A-Z]\\w*$", "DAL\\.(create|public)$"];
const DAL_SOURCES_DEFAULTS = ["\\.dal$"];

type ActionFunction =
	| ESTree.ArrowFunctionExpression
	| ESTree.FunctionDeclaration
	| ESTree.FunctionExpression;

interface ExportedAction {
	fn: ActionFunction;
	name: string;
}

function exportedActions(
	node: ESTree.ExportNamedDeclaration | ESTree.ExportDefaultDeclaration,
): ExportedAction[] {
	const declaration = node.declaration;
	if (declaration === null || declaration === undefined) return [];
	if (declaration.type === "FunctionDeclaration") {
		return [{ fn: declaration, name: declaration.id?.name ?? "default" }];
	}
	if (declaration.type === "ArrowFunctionExpression" || declaration.type === "FunctionExpression") {
		return [{ fn: declaration, name: "default" }];
	}
	if (declaration.type !== "VariableDeclaration") return [];
	return declaration.declarations.flatMap((declarator) => {
		const init = declarator.init;
		if (init === null || (init.type !== "ArrowFunctionExpression" && init.type !== "FunctionExpression")) {
			return [];
		}
		return [{ fn: init, name: declarator.id.type === "Identifier" ? declarator.id.name : "action" }];
	});
}

/** Los nombres de todo lo que se llama dentro de `node`, como `requireUser` o `PostDAL.create`. */
function calleesIn(node: ESTree.Node, text: (node: ESTree.Node) => string): string[] {
	const found: string[] = [];
	const visit = (current: unknown): void => {
		if (typeof current !== "object" || current === null) return;
		if (Array.isArray(current)) {
			for (const item of current) visit(item);
			return;
		}
		const type: unknown = Reflect.get(current, "type");
		if (typeof type !== "string") return;
		// SAFETY: un objeto con `type` string dentro del AST de oxc es un nodo ESTree.
		const astNode = current as ESTree.Node;
		if (astNode.type === "CallExpression") found.push(text(astNode.callee));
		if (astNode.type === "ArrowFunctionExpression" || astNode.type === "FunctionExpression") return;
		for (const [key, value] of Object.entries(current)) {
			if (key !== "parent") visit(value);
		}
	};
	visit(node);
	return found;
}

/**
 * Una server action es un endpoint POST público: nadie garantiza que llegue desde tu
 * formulario. Cada action exportada pasa por la identidad: llama a `requireUser()`,
 * a una factoría de DAL (`XDAL.create()` autenticada, `XDAL.public()` pública y
 * declarada), o a algo importado de un `*.dal`, que según `data-layer.md` es donde
 * vive la autorización. Lo que reporta es la action que no toca ninguna de las tres:
 * la que escribe una cookie, llama a un vendor o devuelve datos sin preguntar quién.
 */
const actionAssertsIdentityRule = defineRule({
	meta: {
		type: "problem",
		docs: {
			description:
				"Require every exported server action to go through identity: requireUser, a DAL factory, or a call into a *.dal module.",
		},
		messages: {
			missing:
				"Server action `{{name}}` is a public POST endpoint and never goes through identity: no `requireUser()`, no `XDAL.create()` or `XDAL.public()`, no call into a *.dal. Anyone can call it with any payload. A genuinely public action takes a disable comment that says why.",
		},
		schema: [
			{
				type: "object",
				properties: {
					identity: { type: "array", items: { type: "string" } },
					dalSources: { type: "array", items: { type: "string" } },
				},
				additionalProperties: false,
			},
		],
	},
	create(context) {
		const identity = (stringOptions(context.options, "identity") ?? IDENTITY_DEFAULTS).map(
			(source) => new RegExp(source),
		);
		const dalSources = (stringOptions(context.options, "dalSources") ?? DAL_SOURCES_DEFAULTS).map(
			(source) => new RegExp(source),
		);
		const text = (node: ESTree.Node): string => context.sourceCode.getText(node);
		const dalNames = new Set<string>();
		let isServer = false;

		const goesThroughIdentity = (callee: string): boolean =>
			identity.some((pattern) => pattern.test(callee)) ||
			dalNames.has(callee.split(/[.?(]/)[0] ?? "");

		const check = (node: ESTree.ExportNamedDeclaration | ESTree.ExportDefaultDeclaration): void => {
			if (!isServer) return;
			for (const { fn, name } of exportedActions(node)) {
				if (!fn.async) continue;
				if (!calleesIn(fn.body, text).some(goesThroughIdentity)) {
					context.report({ node: fn, messageId: "missing", data: { name } });
				}
			}
		};

		return {
			Program(node) {
				isServer = hasDirective(node, "use server");
				dalNames.clear();
			},
			ImportDeclaration(node) {
				if (!dalSources.some((pattern) => pattern.test(node.source.value))) return;
				for (const specifier of node.specifiers) dalNames.add(specifier.local.name);
			},
			ExportNamedDeclaration: check,
			ExportDefaultDeclaration: check,
		};
	},
});

const housePlugin = eslintCompatPlugin({
	meta: { name: "house" },
	rules: {
		"no-server-code-in-client": noServerCodeInClientRule,
		"dal-imports-server-only": dalImportsServerOnlyRule,
		"action-asserts-identity": actionAssertsIdentityRule,
	},
});

export default housePlugin;
