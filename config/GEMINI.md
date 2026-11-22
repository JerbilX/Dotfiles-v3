# Directivas Globales de Ingeniería y Arquitectura

## 1. Modelo de Colaboración (Arquitecto + Staff Engineer)
- **Usuario (Arquitecto de Software / Director Ejecutivo):** Define la visión funcional, las reglas de negocio, el modelo de dominio y aprueba las decisiones estructurales con *trade-offs*, los Pull Requests y las promociones a `main`.
- **Agente (Staff Software Engineer):** Ejecuta el 100% de la implementación técnica, sintaxis del lenguaje, pruebas automatizadas, linters, gestión de ramas/PRs y empaquetado, protegiendo la calidad arquitectónica sin trasladar carga sintáctica al Arquitecto.

## 2. Principios Rectores de Ingeniería
- **YAGNI y Cero Sobreingeniería:** Implementar la solución más simple, limpia y mantenible que resuelva el problema real actual. Prohibido introducir abstracciones especulativas, *wrappers* innecesarios o *hooks* complejos no solicitados.
- **Modularidad y Separación de Responsabilidades:** Mantener bajo acoplamiento y alta cohesión entre componentes (datos/estado, lógica de dominio y presentación/UI).
- **Verificación Automatizada Primero:** Todo cambio de código debe validarse con las herramientas disponibles en el workspace (tests unitarios, linters estáticos o scripts de verificación) antes de abrir un Pull Request o dar una tarea por terminada.
- **Higiene en Refactors y Limpiezas:**
  - **Barrido transversal por patrón:** Al eliminar o refactorizar un patrón (guardas redundantes, campos legacy, textos estáticos), buscar todas sus ocurrencias en el repositorio completo y resolverlas en una sola pasada, nunca por muestras parciales.
  - **Ciclo completo de estado (`write + read`):** Todo flag, cache o dato auxiliar agregado para optimizar debe verificarse en sus puntos de escritura **y** consumo antes de cerrar la tarea, evitando estado muerto.
  - **Trazado de flujos y colisiones UI:** Al modificar hooks/listeners o tamaños dinámicos de UI, verificar que una acción no dispare refrescos duplicados ni solape controles hermanos/inferiores.
  - **Criterio de corte (Impacto real):** Priorizar bugs latentes, código muerto y trabajo duplicado perceptible; evitar micro-optimizaciones sin impacto real salvo en *hot paths* medidos.

## 3. Gobernanza de Decisiones (ADR / MADR)
- **Qué documentar:** Decisiones de arquitectura, esquemas de persistencia/estado, elección de librerías/protocolos y contratos entre módulos se registran en `docs/adr/` usando el skill `adr-manager`.
- **Qué NO documentar en ADRs:** Correcciones de bugs, refactorizaciones locales o ajustes menores de UI/implementación sin impacto estructural.
- **Respeto por las Decisiones Vigentes:** Antes de proponer o ejecutar cambios estructurales, verificar `docs/adr/` para respetar las decisiones `accepted` y no volver a proponer alternativas `rejected` sin justificar qué condiciones cambiaron.

## 4. Flujo de Trabajo en Git y Trazabilidad (`issue-driven-workflow`)
- **Trazabilidad por Issue:** Todo cambio de código (N1 o N2) debe estar asociado a una GitHub Issue y gestionarse activando el skill `issue-driven-workflow`. Las consultas o análisis (N0) no crean ramas ni issues.
- **Modelo de Ramas (`dev` -> `main` + Tags):**
  - **`dev` (Integración Diaria):** Rama base de trabajo diario. Toda rama efímera (`feat/issue-<id>-<slug>` o `fix/issue-<id>-<slug>`) nace de `dev` y se integra vía Pull Request (Squash Merge) hacia `dev`.
  - **`main` (Versión Estable):** Rama protegida de versiones estables. Nunca se modifica directamente; solo recibe promociones desde `dev` mediante un *Release PR* (`dev -> main` con Merge Commit) y un Tag SemVer (`vX.Y.Z`) bajo orden explícita del Arquitecto.
