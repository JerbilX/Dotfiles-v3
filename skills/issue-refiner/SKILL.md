---
name: issue-refiner
description: >-
  Default backlog intake and refinement protocol (read-only analysis, targeted questions, explicit draft confirmation before creating GitHub Issues, and hard stop without implementing code). ACTIVATE by default whenever the user describes a bug, feature idea, UI observation, or change request without an explicit order to implement it immediately.
---

# Issue Refiner — Refinamiento de Backlog por Defecto ("Backlog First")

Protocolo canónico para transformar comentarios, reportes de bugs, observaciones de UI o ideas funcionales en GitHub Issues claras y accionables, **sin iniciar implementación ni crear issues a ciegas**.

---

## Restricciones Duras (Hard Guardrails)

1. **Modo Solo Lectura:** Prohibido editar archivos del proyecto, crear ramas o iniciar implementación durante este flujo.
2. **Doble Gate Obligatorio:** Nunca ejecutar `gh issue create` sin haber completado antes el análisis del contexto, las preguntas necesarias al Arquitecto y la **confirmación explícita del borrador**.
3. **Parada Dura tras Crear:** Una vez creadas las issues aprobadas en GitHub, **detenerse inmediatamente** sin comenzar a implementar.
4. **Comandos de Red Puros:** Ejecutar cada comando `gh` como una llamada individual pura (nunca encadenar con `&&`, `;` ni `||` junto a otros comandos para preservar el *prefix-matching* de Antigravity).

---

## Protocolo Obligatorio en 4 Pasos

### Paso 1: Análisis Read-Only del Contexto (Antes de preguntar)
1. Inspeccionar el código y archivos relevantes para basar las preguntas en hechos reales y evitar preguntar lo que el código ya responde.
2. Revisar `docs/adr/` (si existe en el repositorio) para respetar decisiones `accepted` y no reabrir opciones `rejected`.
3. Consultar el backlog abierto con `gh issue list --state open --limit 50` (llamada individual) para evitar duplicados o detectar si conviene ampliar o relacionar una issue existente.
4. Evaluar granularidad: determinar si el pedido corresponde a **1 issue atómica** o si conviene dividirlo en **varias issues independientes**, pensadas para ser ejecutadas limpiamente luego mediante `"dame al PM"` / `project-manager`.

### Paso 2: Entrevista Enfocada (Gate 1: Preguntas)
- Formular únicamente preguntas de alto valor que el código no resuelva (alcance funcional, casos borde, criterios de aceptación, división en issues o necesidad de ADR).
- Usar `ask_question` para decisiones con opciones claras (colocando la opción recomendada primero con el prefijo `(Recommended)`), o una lista numerada breve con una propuesta concreta por punto si son preguntas abiertas.
- Si tras analizar el código no quedan ambigüedades reales, omitir las preguntas y pasar directamente al Paso 3 resumiendo lo verificado.

### Paso 3: Borrador y Confirmación Explícita (Gate 2: Antes de crear)
- Presentar un borrador compacto de cada issue propuesta **antes** de ejecutar `gh issue create`:
  - **Título:** formato Conventional Commits en inglés (`<tipo>(<alcance>): <descripción>`, salvo regla local distinta).
  - **Nivel estimado:** `N1` o `N2`.
  - **Modelo recomendado (Regla Hydrogen-First y `Ceremony != Model`):** `<fast|balanced|deep> (<Modelo Concreto>)`, aplicando la tabla canónica siguiente (evitando variantes *Orchestrator* para subagentes implementadores) según complejidad cognitiva independiente del volumen de archivos (`N1` vs `N2`):

| Perfil | Modelo Concreto Vigente | Parámetro `Model` en `invoke_subagent` | Criterio Objetivo de Selección |
| :--- | :--- | :--- | :--- |
| `fast` | *Gemini 4 Hydrogen Medium* | `"inherit"` si la sesión ya corre en *Hydrogen*, o `"flash"` si corre en un modelo superior | **Default absoluto para `N1` y `N2`:** Toda tarea que extienda patrones existentes del repositorio con requisitos claros (UI/controles, campos simples en modelo/códec, eventos conocidos, traducciones, tests o análisis), sin importar cuántos archivos toque. |
| `balanced` | *Gemini 4 Carbon Medium* | `"inherit"` en sesión `balanced` | Solo ante lógica condicional/máquinas de estado entre entidades, empaquetado binario delicado sin molde previo, refactors estructurales entre capas, o como **escalado automático si un subagente `fast` rebota en `pr-reviewer`**. |
| `deep` | *Neon High / Pro* | `"pro"` (o `"inherit"` si la sesión ya corre en `deep`) | Exclusivamente para coordinación/estado multi-actor o multi-cliente, rediseño estructural de protocolos/ADRs de transporte o debugging crítico sin causa raíz conocida. |

  - **Desacople `Ceremony != Model`:** El nivel de ceremonia (`N1` vs `N2`, volumen de archivos o necesidad de `pr-reviewer`) **no** determina el modelo. Tareas largas pero mecánicas son `N2` con perfil `fast`.
  - **Contexto / Alcance:** módulos afectados y si actualiza o se relaciona con alguna issue abierta.
  - **Criterios de aceptación:** lista breve y verificable.
- Pedir confirmación explícita al Arquitecto (*"¿Confirmás que cree esta(s) issue(s) así, o ajustamos algo?"*) y **esperar su respuesta**.

### Paso 4: Creación Controlada y Parada Dura
1. Recién tras el OK explícito del Arquitecto:
   - Redactar `.issue_body` usando la herramienta nativa de escritura de archivos (formato `N1` o `N2` compatible con `issue-driven-workflow`), encabezando siempre el archivo con los metadatos planos (sin depender de GitHub Labels):
     ```markdown
     **Ceremony:** <N1|N2>
     **Model:** <fast|balanced|deep> (<Modelo Concreto>)
     ```
   - Ejecutar la creación como llamada individual pura:
     ```bash
     gh issue create --title "<tipo>(<alcance>): <descripción>" --body-file .issue_body
     ```
   - Limpiar `.issue_body` en un paso local separado (`rm -f .issue_body`).
   - *(Opcional)* Indexar en Projects v2 si el repositorio utiliza `.repo-config.json` y no tiene auto-add activo.
2. Entregar el resumen de las issues creadas (número, título y URL) y **detenerse aquí** (sin crear ramas ni tocar código), indicando que quedan listas en el backlog para `"dame al PM"` o una futura orden de ejecución.

---

## Cuándo NO Activar Este Skill

- **Consultas puras (`N0`):** Preguntas, explicaciones o auditorías informativas sin pedido de cambio.
- **Órdenes explícitas de ejecución:** Cuando el usuario pide `"dame al PM"`, elige una opción del PM, ordena implementar directamente (*"implementalo"*, *"arreglalo ahora"*, *"hacé el cambio"*, *"ejecutá #X"*) o se encuentra en una iteración activa en vivo sobre una rama ya abierta.
