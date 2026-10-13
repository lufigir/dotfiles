# Evidencia

Lo que respalda el catálogo y lo que se sabe de los detectores. Leído el 2026-10-13.

## Rasgos de los textos generados

- **Alonso Simón, L., Fernández-Pampillón, A. M., Fernández Trinidad, M. y Márquez Cruz, M.
  (2025).** ¿Tienen GPT-3.5 y GPT-4 un estilo de escritura diferente del estilo humano? Un estudio
  exploratorio para el español. *RAEL*, 23(1), 34-54. DOI 10.58859/rael.v23i1.666. Corpus de 180
  textos (artículos científicos, noticias, reseñas). 17 de 41 rasgos separan a los modelos de las
  personas: los modelos usan más adjetivos y más puntos (más oraciones por texto); las personas
  más adverbios, pronombres, comillas, paréntesis, comas, dos puntos, punto y coma y guiones. Los
  artículos científicos son el género con más diferencias de puntuación; GPT-4 se acerca más a lo
  humano que GPT-3.5. Respalda §10 y la sección de rasgos humanos.
- **Reinhart, A. et al. (2024).** Do LLMs write like humans? Variation in grammatical and
  rhetorical styles. arXiv 2410.16107. En inglés, con los rasgos de Biber: los modelos ajustados
  con instrucciones usan cláusulas de participio presente 2 a 5 veces más que las personas y
  nominalizaciones 1,5 a 2 veces más; el ajuste los lleva a un estilo denso y nominal. Respalda
  §13 y §14 por analogía; no hay réplica en español.
- **Wikipedia: Signs of AI writing** (WikiProject AI Cleanup) y la skill
  [humanizer](https://github.com/blader/humanizer) (MIT, Siqi Chen), de donde vienen la teoría
  del "elegir para todos los lectores" y la estructura de §1 a §9, §11 a §13 y §15 a §23.
- Las listas de conectores de §7 ("cabe destacar", "en este sentido") salen de guías docentes y
  blogs; no encontramos un estudio de corpus que las mida. Por eso §7 es *débil sola*.

## Detectores

- **Weber-Wulff, D. et al. (2023).** Testing of detection tools for AI-generated text. arXiv
  2306.15666. Catorce herramientas: ninguna supera el 80 % de exactitud y solo cinco el 70 %. Los
  falsos positivos van del 0 % (Turnitin) al 50 % (GPTZero). Con edición manual o paráfrasis,
  cerca de la mitad del texto generado pasa por humano. Concluyen que un estudiante acusado solo
  con esa salida no tiene cómo defenderse.
- **Liang, W. et al. (2023).** GPT detectors are biased against non-native English writers.
  arXiv 2304.02819. Los detectores marcan como IA el texto de escritores no nativos por su baja
  perplejidad.
- **Shan, Z., Lee, Y. y Hao, S. (2026).** AI Writers Have a Consistent Stylometric Footprint,
  but AI Editors Do Not. arXiv
  2608.27855. Generar con IA deja una huella estilométrica estable (entropía, diversidad
  léxica); editar un texto humano con IA casi no la deja (AUC 0,80 con rasgos de estilo), pero un
  detector entrenado para edición, EditLens, la distingue con AUC 0,97.

Consecuencia práctica: un detector no prueba autoría en ningún sentido. La defensa ante una
acusación es el rastro del trabajo (historial de versiones del Docs, scripts, datos, notas), y un
texto editado con IA puede ser señalado por los detectores de edición aunque las ideas sean
propias. Si la entrega admite apoyo de IA, decláralo como pida el curso.
