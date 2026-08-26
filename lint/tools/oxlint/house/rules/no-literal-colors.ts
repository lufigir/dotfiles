import { defineRule } from "@oxlint/plugins";
import type { ESTree } from "@oxlint/plugins";

/**
 * La paleta literal de Tailwind.
 *
 * Incluye a propósito los prefijos de gradiente (`from`, `via`, `to`) y los que se
 * olvidan siempre (`divide`, `placeholder`, `accent`, `caret`, `ring-offset`). Una
 * regla que solo mira `bg` y `text` deja media superficie sin linter y, peor, da la
 * sensación de estar cubierta.
 */
const LITERAL_PALETTE_CLASS =
	/\b(?:bg|text|border|ring|ring-offset|fill|stroke|from|via|to|decoration|outline|accent|caret|shadow|divide|placeholder)-(?:red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|slate|gray|zinc|neutral|stone)-\d{2,3}\b/;

/** Reject literal Tailwind palette classes so colour stays decided in one place. */
export const noLiteralColorsRule = defineRule({
	meta: {
		type: "problem",
		docs: {
			description:
				"Disallow literal Tailwind palette classes in favour of semantic design tokens.",
		},
		messages: {
			literalColor:
				"`{{ match }}` is a literal colour. Use a semantic token (`bg-primary`, `text-muted`): the palette is decided once in the global stylesheet, not in every component.",
		},
	},
	createOnce(context) {
		/**
		 * Tres nodos, no uno. Un string suelto (`const cls = "bg-blue-500"`), el texto
		 * de un atributo JSX, y cada trozo estático de un template literal, que es
		 * donde acaban las clases en cuanto alguien mete una condición. La versión de
		 * esta regla escrita como selector sobre `Literal` se perdía el tercero.
		 */
		const checkString = (node: ESTree.Node, value: unknown) => {
			if (typeof value !== "string") return;

			const found = LITERAL_PALETTE_CLASS.exec(value);
			if (found === null) return;

			context.report({ node, messageId: "literalColor", data: { match: found[0] } });
		};

		return {
			Literal(node) {
				checkString(node, node.value);
			},
			JSXText(node) {
				checkString(node, node.value);
			},
			TemplateElement(node) {
				checkString(node, node.value.cooked);
			},
		};
	},
});
