# Detectores

Cómo correr el paso 6 y qué esperar de él. La evidencia está en [`evidencia.md`](evidencia.md#detectores).

## Qué miden

Los detectores comerciales no buscan palabras sueltas: aprenden la huella del ajuste por
instrucciones (texto plano, predecible, de baja entropía, nominal, con la puntuación reducida).
Por eso un modelo base, sin ajuste, pasa por humano en GPTZero y Pangram, y por eso pedirle a un
modelo ajustado que "suene humano" puede subir el puntaje: cambia palabras y deja la forma.

Consecuencias para reescribir:

- Lo que baja el puntaje es lo mismo que mejora el texto: oraciones de largo y forma variados,
  verbos con sujeto humano, palabras cortas y comunes, la puntuación del autor, su postura y sus
  detalles. Es el catálogo aplicado a fondo, no otro método.
- Cambiar sinónimos no mueve nada. Reestructura el párrafo marcado entero.
- Un texto que Claude reescribe sigue siendo texto de un modelo ajustado. Un pasaje que el autor
  no escribió puede seguir marcado aunque no quede ninguna marca del catálogo; lo que lo resuelve
  es que el autor lo reescriba con sus palabras o aporte el detalle que solo él tiene.
- Los detectores también marcan texto humano: escritura formal, académica, de no nativos, y
  textos humanos apenas editados con IA (38 a 80 % en un estudio de 2026). Un puntaje alto no
  prueba autoría, y la defensa ante una acusación es el rastro del trabajo: historial de versiones
  del Docs, scripts, datos, notas.

## Qué no funciona

Errores de tipeo puestos a propósito, homoglifos (letras de otro alfabeto que se ven iguales),
espacios invisibles y parafraseadores automáticos. Dañan el texto para quien lo lee, se notan al
copiarlo o al pasarle el corrector, y los humanizadores que los usan producen texto más corto,
más simple y menos variado, que no se parece más al humano. No los uses aunque bajen un puntaje.

## Cuál usar

| Detector | Acceso | Para qué |
|---|---|---|
| Pangram | Web con cuenta, 5 análisis gratis al día; acepta español; API paga (US$0,05 por 100 palabras) | El de referencia: la mejor tasa de falsos positivos en las evaluaciones independientes y el más resistente a humanizadores |
| GPTZero | Web con cuenta, 10.000 palabras al mes gratis; sin API en el plan gratuito | Segunda opinión; marca frases y separa texto mixto |
| Turnitin | Solo por la universidad | Si el curso lo usa, el resultado que importa es el suyo; no hay acceso propio |

Corre Pangram primero. GPTZero cuando Pangram no está disponible o cuando el texto es mixto y
sirve ver qué frases marca. Los detectores gratis sin cuenta (ZeroGPT y similares) fallan con
texto humano en las pruebas publicadas; no sirven para decidir nada.

## Cómo correrlo en Brave

El usuario tiene sesión iniciada en su Brave (`mcp__brave__*`).

1. `list_pages`, luego `new_page` con la URL del detector; las pestañas del usuario quedan como
   están.
2. `take_snapshot`; ubica el área de texto y el botón de análisis por su nombre accesible.
3. `fill` con el texto final completo (sin títulos ni referencias si el detector cuenta palabras
   contra la cuota), clic en analizar, espera el resultado y toma otro snapshot.
4. Anota el veredicto, el porcentaje y los pasajes marcados. Si pide iniciar sesión o se acabó la
   cuota del día, díselo al usuario y sigue con el otro detector.

## El ciclo

1. Corre el detector sobre el texto final del paso 5.
2. Si marca pasajes, vuelve al paso 2 solo con esos párrafos: busca qué marcas quedan, mide el
   ritmo y reestructura; no cambies sinónimos.
3. Corre otra vez. Un análisis por ronda; como mucho tres rondas, porque la cuota gratis es corta.
4. Si después de tres rondas un pasaje sigue marcado, entrégalo marcado: di qué pasaje es, qué
   puntaje tiene y qué le falta (casi siempre, la voz o un detalle del autor). No sigas puliendo a
   costa de la claridad.

Reporta cada ronda: detector, puntaje, pasajes marcados y qué cambiaste.
