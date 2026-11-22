---
name: issue-driven-workflow
description: >-
  Orchestrate task traceability and Git lifecycle using GitHub Issues, ephemeral branches off `dev`, Pull Requests, and stable releases to `main`. ACTIVATE whenever creating or implementing issues, initializing repositories, creating branches, committing changes, opening/merging PRs, or promoting `dev` to `main`. Operates 100% natively with standard `git` and `gh` CLI without external custom scripts.
---

# Issue-Driven Workflow (`dev` -> `main` + SemVer Tags)

Protocolo canónico para el manejo de Git, trazabilidad por GitHub Issues, ciclo de vida de ramas efímeras y promoción de versiones estables, operando de forma **100% nativa con `git` y `gh` CLI**.

---

## 1. Arquitectura de Ramas y Niveles de Ceremonia

### 1.1 Modelo Unificado de Ramas
```text
feat/issue-12-dialogos ──(PR: Squash Merge)──┐
                                             ▼
──────────────────────────────────────────> dev  ──(Release PR: Merge Commit)──> main [Tag: v0.1.0]
                                             ▲
fix/issue-15-savedvars ──(PR: Squash Merge)──┘
```

1. **`main` (Rama Estable / Releases):**
   - Contiene únicamente versiones probadas y estables.
   - Prohibido hacer commits directos o abrir PRs de tareas individuales hacia `main`.
   - Solo recibe código desde `dev` mediante un **Release PR** aprobado por el usuario, acompañado de un Tag SemVer (`vX.Y.Z`).
2. **`dev` (Rama de Integración Continua):**
   - Es la rama activa del día a día.
   - Si en un repositorio aún no existe la rama `dev`, el agente la crea a partir de `main` antes de iniciar la primera tarea (`git switch -c dev main && git push -u origin dev`).
3. **Ramas Efímeras de Tarea (`feat/` y `fix/`):**
   - Todo cambio de desarrollo se aísla en una rama creada desde `origin/dev`:
     - Nuevas funcionalidades, mejoras o refactors: `feat/issue-<id>-<slug>`
     - Corrección de bugs o parches: `fix/issue-<id>-<slug>`

### 1.2 Niveles de Ceremonia (`N0 / N1 / N2`)
- **N0 (Consultas, exploración, dudas de arquitectura o pruebas en `scratch/`):**
   - No requiere Issue ni creación de ramas.
- **N1 (Cambios acotados, fixes rápidos, iteraciones de UI/UX sobre capturas o ajustes de comportamiento sin impacto arquitectónico):**
   - Issue breve (1 a 3 líneas), rama efímera desde `dev`, implementación directa con `edit_file` (sin plan bloqueante ni ADR), validación rápida (`tests` + linter).
   - **Vía Rápida para Pruebas en Vivo (UI / In-Game):** Si el usuario está probando la aplicación/addon en vivo, una vez aplicados los cambios en la rama efímera y pasados los tests locales, **avisa inmediatamente al usuario para que pruebe en vivo** antes de invertir tiempo en redactar documentación adicional, empaquetar `.zip` o abrir el PR. Cuando el usuario confirme que el ajuste funciona como espera (o pida cerrar/mergear), se hace el commit final, PR y merge en un solo paso.
- **N2 (Funcionalidades nuevas desde cero, cambios de arquitectura/persistencia o introducción de nuevos módulos con ADR):**
   - Issue completa (Diagnóstico, Objetivos Técnicos y Criterios de Aceptación), validación de diseño/ADR con el usuario (`adr-manager`), rama efímera desde `dev`, implementación, validación, PR a `dev` y cierre.

---

## 2. Ciclo de Vida Diario por Tarea (E2E sobre `dev`)

> [!IMPORTANT]
> **Regla de Comandos Auto-Aprobables (Sin `&&` en comandos de red):**
> Nunca encadenes comandos de red (`gh ...`, `git fetch`, `git push`, `git pull`) con `&&`, `;` o `||` junto a otros comandos (como `rm -f` o `git switch`). En Antigravity, los operadores `&&` desactivan el *prefix-matching* de **"Always Allow"** y fuerzan a pedir permiso manual en cada ejecución. Ejecuta siempre cada comando `gh` o `git` remoto como una llamada individual pura, y ejecuta las operaciones locales (`git add`, `git commit`, `git switch`, `rm -f`) por separado en el sandbox.

```text
[1. Issue] ──> [2. Rama desde dev] ──> [3. Diseño/ADR] ──> [4. Código + Tests] ──> [5. Commit + Push] ──> [6. PR a dev] ──> [7. Merge + Cierre + Higiene]
```

### Paso 1: Ingesta o Creación de la Issue
- **Si la Issue ya existe:** Leer su especificación con `gh issue view <id>`.
- **Si la tarea surge en el chat y aún no tiene Issue:**
  1. Redactar el cuerpo en `.issue_body` usando la herramienta nativa de escritura de archivos:
     - Para **N1**: Descripción concisa del cambio y criterio de verificación.
     - Para **N2**: Secciones `### Contexto / Problema`, `### Objetivos Técnicos` y `### Criterios de Aceptación`.
  2. Crear la Issue con GitHub CLI (llamada individual sin `&&` para conservar el *prefix-match*):
     ```bash
     gh issue create --title "<tipo>(<alcance>): <descripción>" --body-file .issue_body
     ```
  3. Limpiar el archivo temporal en el paso local siguiente (`rm -f .issue_body`).
  4. *(Opcional - Tablero Projects v2)*: Si el repositorio utiliza un tablero central y no tiene auto-add activo, indexar con `gh project item-add <project_number> --owner @me --url <issue_url>` (usando `.repo-config.json` si existiera).

### Paso 2: Aislamiento en Rama Efímera desde `dev`
1. Sincronizar referencias remotas (llamada individual):
   ```bash
   git fetch --prune origin
   ```
2. Crear la rama efímera desacoplada directamente desde `origin/dev` (y aprovechar para borrar `.issue_body` si quedó del paso anterior):
   ```bash
   git switch --no-track -c <feat|fix>/issue-<id>-<slug> origin/dev
   ```

### Paso 3: Planificación y ADR (Solo N2)
- Si la tarea implica decisiones de arquitectura, esquemas de persistencia o contratos entre módulos, aplicar el skill `adr-manager` (consultar `docs/adr/` y acordar el diseño con el usuario antes de escribir código).
- En tareas N1 o cuando el usuario ya dio una orden ejecutiva directa tras acordar el enfoque en el chat, pasar directo al Paso 4.

### Paso 4: Desarrollo y Verificación Local
- Implementar los cambios utilizando las herramientas nativas de archivos (`edit_file` para archivos existentes).
- Si se implementó un ADR, incluir el comentario de trazabilidad (`-- Ref: docs/adr/NNNN-...` en Lua o `# Ref: docs/adr/NNNN-...` en Python) y asegurar que su estado esté en `status: accepted`.
- Ejecutar las herramientas de verificación del proyecto (linters MCP, `./build.sh check`, `luajit tests/run.lua`, `pytest`, etc.) y confirmar que pasen sin errores.

### Paso 5: Commit Atómico y Push
1. Agregar explícitamente los archivos modificados (evitar `git add .` a ciegas para no subir archivos residuales):
   ```bash
   git add <ruta1> <ruta2>
   ```
2. Escribir el mensaje Conventional Commits en `.commit_msg` mediante herramientas nativas de archivos y ejecutar el commit local:
   ```bash
   git commit -F .commit_msg
   ```
3. Publicar la rama en el remoto (llamada individual sin `&&`):
   ```bash
   git push -u origin <nombre-de-rama>
   ```

### Paso 6: Apertura del Pull Request hacia `dev`
1. Escribir el resumen técnico en `.pr_body` incluyendo la referencia de cierre `Closes #<id>`:
   ```markdown
   ### Resumen de Cambios
   - [Detalle conciso de lo implementado]

   ### Verificación
   - [Tests / Linters ejecutados]

   Closes #<id>
   ```
2. Crear el Pull Request apuntando explícitamente a la base `dev` (llamada individual sin `&&`):
   ```bash
   gh pr create --base dev --title "<tipo>(<alcance>): <descripción>" --body-file .pr_body
   ```
3. Limpiar los archivos temporales locales (`rm -f .issue_body .commit_msg .pr_body`).
4. En tareas **N1** (fuera de `/goal`), reportar al usuario el enlace al PR y aguardar su confirmación para fusionar.

### Paso 6.5: Auditoría Pre-Merge (`pr-reviewer`) — Solo N2 y `/goal`
Si la tarea es **N2** o se está ejecutando bajo **`/goal`**, antes de dar el PR por listo para merge:
1. **Delegar en Subagente Limpio:** Invocar `invoke_subagent` (`TypeName: "self"`, `Role: "PR Staff Reviewer"`) con contexto fresco (para evitar sesgo de autor), pasándole el path/repo y el número de PR recién creado, e instruyéndolo a leer y ejecutar el skill `pr-reviewer` publicando el review automáticamente en GitHub.
2. **Si el veredicto es `REQUEST_CHANGES`:**
   - Corregir los hallazgos `BLOCKER`, hacer commit y `git push` en la misma rama efímera, y volver a lanzar la auditoría hasta obtener `APPROVE` (si un blocker requiere decisión de diseño/arquitectura del usuario y no estás en `/goal`, consultar al usuario).
3. **Si el veredicto es `APPROVE`:**
   - **En tarea N2 normal:** Reportar al usuario el enlace del PR junto con el resumen del review publicado y **esperar su confirmación** para ejecutar el Paso 7 (Merge).
   - **En ejecución `/goal`:** Continuar autónomamente sin detenerse a preguntar (ejecutar Paso 7 si el goal incluye integrar a `dev` o avanzar a la siguiente tarea).

### Paso 7: Merge a `dev`, Cierre de Issue e Higiene Local
Cuando el usuario apruebe el PR (*"aprobado, mergeá"*, *"mergealo"*):
1. **Squash Merge y borrado de rama remota (llamada individual):**
   ```bash
   gh pr merge <pr_id> --squash --delete-branch
   ```
2. **Cierre garantizado de la Issue (llamada individual):**
   Dado que en GitHub `Closes #<id>` solo cierra automáticamente el ticket cuando el PR apunta a la *Default Branch* del repositorio, cerrar explícitamente la Issue si sigue abierta para mantener el backlog al día:
   ```bash
   gh issue close <issue_id> --reason completed
   ```
3. **Higiene local nativa (volver a `dev` limpia):**
   ```bash
   git switch dev
   ```
   ```bash
   git pull --prune --ff-only
   ```
   ```bash
   git branch -D <rama-efimera>
   ```

---

## 3. Promoción de Versión Estable (`dev` -> `main` + Tag SemVer)

Cuando el usuario ordene promover los avances de `dev` a producción/estable (*"pasemos dev a main"*, *"saquemos release v0.1.0"*):

1. **Verificación Previa:** Asegurar que `dev` esté sincronizada y con todas las validaciones en verde.
2. **Apertura del Release PR (`dev` -> `main`):**
   Redactar en `.pr_body` el resumen de las issues y cambios incluidos en la versión y abrir el PR hacia `main`:
   ```bash
   gh pr create --base main --head dev --title "release: vX.Y.Z" --body-file .pr_body
   ```
   *(Limpiar `.pr_body` localmente con `rm -f .pr_body`)*.
3. **Fusión con Merge Commit (`--merge`):**
   > [!IMPORTANT]
   > Entre ramas permanentes (`dev` -> `main`), usar siempre **`--merge`** (y NUNCA `--squash`). El Merge Commit preserva el historial de ancestros común entre `dev` y `main`, evitando conflictos artificiales en futuras promociones.
   ```bash
   gh pr merge <pr_id> --merge
   ```
4. **Creación del Tag SemVer Inmutable (Punto de Rollback Estable):**
   Ejecutar como comandos separados para mantener el *prefix-matching*:
   ```bash
   git switch main
   ```
   ```bash
   git pull --ff-only
   ```
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   ```
   ```bash
   git push origin vX.Y.Z
   ```
   ```bash
   git switch dev
   ```

---

## 4. Escenarios Especiales y Recuperación

Para aprovisionamiento inicial de repositorios, atención de observaciones en Code Review, cierre de spikes de investigación sin código o rollbacks de emergencia, consultar [`references/operations-and-recovery.md`](./references/operations-and-recovery.md).
