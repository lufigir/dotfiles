import { eslintCompatPlugin } from "@oxlint/plugins";

import { noLiteralColorsRule } from "./rules/no-literal-colors.ts";

/**
 * Reglas de la casa: lo que anti-slop no cubre y oxlint no trae.
 *
 * `no-literal-colors` existe aquí porque `eslint/no-restricted-syntax`, que es como
 * se escribía esta regla bajo ESLint, no está implementada en oxlint (la doc la
 * lista, el binario no la tiene: verificado contra 1.80.0). Escribirla como regla
 * propia sale mejor que conservar ESLint por una sola regla, y de paso caza los
 * template literals que un selector sobre `Literal` se perdía.
 */
const housePlugin = eslintCompatPlugin({
	meta: { name: "house" },
	rules: {
		"no-literal-colors": noLiteralColorsRule,
	},
});

export default housePlugin;
