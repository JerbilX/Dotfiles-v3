# Directivas Globales de Ingeniería y Arquitectura

## 1. Modelo de Colaboración (Arquitecto + Staff Engineer)
- **Usuario (Arquitecto):** Define visión funcional, reglas de negocio, modelo de dominio y aprueba decisiones estructurales con *trade-offs*, PRs y promociones a `main`.
- **Agente (Staff Engineer):** Ejecuta el 100% de la implementación técnica, pruebas automatizadas, linters, ramas/PRs y empaquetado, protegiendo la calidad arquitectónica sin trasladar carga sintáctica al Arquitecto.

## 2. Principios Rectores de Ingeniería
- **YAGNI y Cero Sobreingeniería:** Implementar la solución más simple, limpia y mantenible para el problema real actual. Prohibido introducir abstracciones especulativas, *wrappers* innecesarios o *hooks* complejos no solicitados.
- **Modularidad y Separación de Responsabilidades:** Mantener bajo acoplamiento y alta cohesión entre datos/estado, lógica de dominio y presentación/UI.
- **Verificación Automatizada Primero:** Validar todo cambio con las herramientas del workspace (tests unitarios, linters o scripts) antes de abrir PR o dar una tarea por terminada.
- **Higiene en Refactors y Limpiezas:**
  - **Barrido transversal:** Al eliminar o refactorizar un patrón, buscar todas sus ocurrencias en el repo y resolverlas en una sola pasada.
  - **Ciclo completo de estado (`write + read`):** Verificar escritura **y** consumo de todo flag, caché o dato auxiliar para evitar estado muerto.
  - **Trazado de flujos y UI:** Al modificar hooks/listeners o tamaños dinámicos, verificar que no haya refrescos duplicados ni solapamiento de controles.
  - **Criterio de corte:** Priorizar bugs latentes, código muerto y duplicación perceptible; evitar micro-optimizaciones salvo en *hot paths* medidos.

## 3. Gobernanza de Decisiones (`adr-manager`)
- Documentar en `docs/adr/` mediante el skill `adr-manager` decisiones de arquitectura, persistencia/estado, librerías/protocolos y contratos entre módulos (no bugfixes ni refactors locales).
- Consultar `docs/adr/` antes de proponer cambios estructurales para respetar decisiones `accepted` y no reabrir alternativas `rejected` sin justificar qué condiciones cambiaron.

## 4. Enrutamiento de Entrada, Backlog y Flujo Git
- **Backlog First (`issue-refiner`):** Ante bug, mejora, idea o detalle UI **sin orden explícita de ejecución**, NO editar código, NO crear ramas ni ejecutar `gh issue create` directo; activar el skill `issue-refiner` (análisis read-only → preguntas → borrador confirmado → creación y parada dura). Consultas puras (`N0`) se responden directo.
- **Ejecución y Ramas (`issue-driven-workflow`):** Solo implementar ante orden directa (*"implementalo"*, *"arreglalo"*, *"ejecutá #X"*), `"dame al PM"` o rama activa en pruebas en vivo (`N1`). Todo cambio se asocia a una Issue y sigue `issue-driven-workflow`: ramas efímeras (`feat/issue-<id>-<slug>` o `fix/issue-<id>-<slug>`) desde `dev` con Squash Merge a `dev`; `main` solo recibe *Release PR* (`dev -> main`, Merge Commit) + Tag SemVer bajo orden explícita.
- **Modo Ejecutivo (`project-manager`):** Cuando el Arquitecto pida **`"dame al PM"`** (o *"¿cómo seguimos?"*), activar el skill `project-manager` (inspección, agrupación por dificultad sin mostrar IDs técnicos, opciones numeradas, ejecución autónoma por grupo y cierre con hallazgos).
- **Perfiles de Modelo (`fast` / `balanced` / `deep`):** Usar `fast` (*Gemini 4 Hydrogen Medium*, `Ceremony != Model`) como default para `N1` y `N2`, evitando variantes *Orchestrator* en implementadores. Ver tabla canónica completa en `skills/issue-refiner/SKILL.md`.
