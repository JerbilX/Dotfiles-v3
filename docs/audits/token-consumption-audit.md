# Auditoría Empírica de Consumo de Tokens y Fugas Silenciosas en el Ecosistema de Agentes y Skills

- **Issue:** `JerbilX/Dotfiles-v3#30`
- **Fecha:** 2026-11-28
- **Alcance:** Etapa de **solo análisis** (sin modificaciones de código, `GEMINI.md` ni skills).
- **Repositorios y fuentes inspeccionadas:**
  - `Dotfiles-v3` (`config/GEMINI.md`, `config/skills.json`, `bootstrap.sh`, `skills/`, `plugins/eso-addon-suite/`, `templates/`)
  - `Project-Manager-Agent` (`skill/project-manager/SKILL.md`, `prompts/staff_pm.md`, `src/project_manager/*.py`)
  - `PR-Reviewer-Agent` (`skill/pr-reviewer/SKILL.md`, `prompts/staff_reviewer.md`, `src/pr_reviewer/*.py`)
  - `Codebase-Auditor-Agent` (`skill/codebase-auditor/SKILL.md`, `prompts/staff_auditor.md`, `src/codebase_auditor/*.py`)
  - Proyectos satélite en `/home/jerbilx/Proyectos-IA-V3/` (`AGENTS.md`, `.agents/rules/`, `.agents/skills/`, `.repo-config.json`)
  - Logs locales de sesiones en `~/.gemini/antigravity/brain/*/.system_generated/logs/transcript.jsonl`

---

## 1. Resumen Ejecutivo y Diagnóstico Empírico

El aumento en el consumo de tokens **no se explica únicamente por el volumen de desarrollo**, sino por una **amplificación estructural de contexto y turnos** introducida por la arquitectura actual de orquestación multi-subagente (`project-manager` + `issue-driven-workflow` + `pr-reviewer`).

### 1.1 Medición Empírica en Sesiones Recientes (`~/.gemini/antigravity/brain/`)

Se analizaron las **120 sesiones más recientes** con `transcript.jsonl` disponible (de un total de 570 directorios de sesión en `brain/`):

| Métrica Observada (120 sesiones recientes) | Sesiones Padre (`parent`) | Subagentes (`subagent`) | Total Ecosistema |
| :--- | :---: | :---: | :---: |
| Cantidad de sesiones | 38 | 82 | **120** |
| Turnos promedio por sesión | 20.3 | 14.7 | **16.5** |
| Tokens procesados totales (`input + cache_read + output`) | 36,591,195 (30.8%) | 82,247,469 (69.2%) | **118,838,664** |

- **69.2% del volumen total de tokens procesados ocurre dentro de subagentes**, no en la conversación principal del usuario.
- En la muestra de las **100 sesiones más recientes**, se registraron **66 invocaciones `invoke_subagent`**:
  - `TypeName: "self", Model: "inherit"`: **54** (81.8%)
  - `TypeName: "self", Model: "flash"`: **11** (16.7%)
  - `TypeName: "research", Model: "inherit"`: **1** (1.5%)
  - **98.5% (65/66)** de los subagentes invocados son `TypeName: "self"`, heredando el prompt base completo, herramientas, `GEMINI.md` y catálogo de skills.

### 1.2 Distribución por Modelo (100 sesiones más recientes)

| Modelo (`PLANNER_RESPONSE.model`) | Sesiones | Turnos | Input sin caché | Cache Read | Output | Contexto Total Procesado |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `gemini-4-hydrogen-medium` | 77 | 1,224 | 6,830,151 | 60,836,322 | 687,084 | **68,353,557** |
| `gemini-4-carbon-medium` | 13 | 199 | 1,812,125 | 17,614,429 | 316,482 | **19,743,036** |
| `gemini-4-hydrogen-tiered-high` | 11 | 164 | 1,147,454 | 10,189,551 | 194,433 | **11,531,438** |
| `claude-opus-5-5-low` | 4 | 62 | 274,982 | 2,570,117 | 27,792 | **2,872,891** |
| `claude-sonnet-5-5-low` | 2 | 13 | 101,330 | 354,075 | 5,603 | **461,008** |

### 1.3 Costo Real Medido de Lotes Completos (`"dame al PM"`)

Reconstruyendo árboles completos padre + subagentes hijos desde `transcript.jsonl`:

| Sesión Padre | Issues / Subagentes | Turnos (Padre + Hijos) | Input sin caché | Output | Contexto Total (`in + cache + out`) | Modelos usados |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| `8322d4cc` (`JeanPierre`) | 4 issues / 8 subs | 137 (32 + 105) | 787,237 | 111,688 | **8,024,112** | `opus-low` (2), `hydrogen-tiered-high` (6) |
| `00a56585` | 4 issues / 8 subs | 128 (44 + 84) | 591,644 | 46,215 | **4,771,147** | `hydrogen-medium` |
| `679b41e2` (`ESOInventoryHelper`) | 4 issues / 8 subs | 128 (45 + 83) | 588,095 | 47,250 | **5,071,756** | `hydrogen-medium` |
| `55ea70f3` | 3 issues / 6 subs | 121 (41 + 80) | 764,757 | 84,816 | **7,639,346** | `hydrogen-medium` |
| `89f3647e` (`RPQuest`) | 2 issues / 4 subs | 94 (26 + 68) | 1,025,235 | 159,343 | **11,912,750** | `carbon-medium` |
| `65d48023` | 2 issues / 4 subs | 87 (27 + 60) | 742,779 | 148,725 | **7,138,638** | `hydrogen-tiered-high`, `carbon-medium` |

**Dato clave:** Un lote pequeño de **4 issues** en `gemini-4-hydrogen-medium` consume **128 turnos** y **~4.8M–5.1M de tokens procesados** (~590K de input sin caché + ~47K de output). Si el mismo patrón corre en `gemini-4-carbon-medium` (`89f3647e`, solo 2 issues), escala a **11.9M de tokens procesados** (1.03M sin caché, 159K de output).

---

## 2. Inventario Transversal de Contexto Estático

### 2.1 Peso Fijo por Turno (`step_index == 1`)

Medido directamente en `n=96` sesiones con `step_index == 1` (antes de leer archivos o ejecutar comandos):
- **Mínimo:** `10,372` tokens
- **Mediana:** `18,755` tokens
- **Máximo:** `31,776` tokens

Diferencia observada por repositorio/plugin en `gemini-4-hydrogen-medium`:
- `Dotfiles-v3`: **17,535 – 18,296 tokens**
- `ESOInventoryHelper` (plugin `eso-addon-suite` + `eso-mcp-server`): **19,150 – 19,829 tokens**
- `RPQuest` (`eso-addon-suite` + `eso-mcp-server` + `.agents/rules/release-and-docs.md`): **21,168 – 22,738 tokens** (+3,000 a +4,000 tokens fijos por cada turno)
- `JeanPierre` en `claude-opus-5-5-low`: **27,156 – 27,365 tokens**

### 2.2 Archivos de Configuración, Skills y Prompts del Ecosistema

| Repositorio | Archivo | Líneas | Bytes | Carga |
| :--- | :--- | :---: | :---: | :--- |
| `Dotfiles-v3` | `config/GEMINI.md` | 55 | **8,694** | Fija en **todo turno** de toda sesión/subagente |
| `Dotfiles-v3` | `skills/issue-driven-workflow/SKILL.md` | 211 | **13,316** | Bajo demanda (leído 37 veces en 100 sesiones) |
| `Dotfiles-v3` | `skills/issue-driven-workflow/references/operations-and-recovery.md` | 77 | **3,271** | Bajo demanda |
| `Dotfiles-v3` | `skills/adr-manager/SKILL.md` | 148 | **8,941** | Bajo demanda |
| `Dotfiles-v3` | `skills/issue-refiner/SKILL.md` | 67 | **6,029** | Bajo demanda (leído 10 veces) |
| `Dotfiles-v3` | `plugins/eso-addon-suite/rules/AGENTS.md` | 60 | **5,558** | Fija en repos ESO con plugin activo |
| `Dotfiles-v3` | `plugins/eso-addon-suite/skills/eso-addon-development/SKILL.md` | 84 | **9,077** | Bajo demanda (leído 10 veces) |
| `Project-Manager-Agent` | `skill/project-manager/SKILL.md` | 104 | **7,764** | Bajo demanda (leído 15 veces) |
| `Project-Manager-Agent` | `prompts/staff_pm.md` | 131 | **10,928** | Bajo demanda (leído 10 veces) |
| `PR-Reviewer-Agent` | `skill/pr-reviewer/SKILL.md` | 48 | **2,985** | Bajo demanda (leído 36 veces) |
| `PR-Reviewer-Agent` | `prompts/staff_reviewer.md` | 61 | **3,694** | Bajo demanda (leído 34 veces) |
| `Codebase-Auditor-Agent` | `skill/codebase-auditor/SKILL.md` | 51 | **2,993** | Bajo demanda (leído 6 veces) |
| `Codebase-Auditor-Agent` | `prompts/staff_auditor.md` | 81 | **4,670** | Bajo demanda (leído 3 veces) |
| Satélite (`rea`) | `rea/AGENTS.md` + `rea/website/AGENTS.md` | 179 | **15,148** | Fija en `rea` |
| Satélite (`RPQuest`) | `.agents/rules/release-and-docs.md` | 24 | **4,903** | Fija en `RPQuest` |
| Satélite (`ESOInventoryHelper`) | `AGENTS.md` | 35 | **4,275** | Fija en `ESOInventoryHelper` |

Desglose por sección de `Dotfiles-v3/config/GEMINI.md` (8,694 bytes):
- `## 7. Perfiles Canónicos de Modelo`: **2,086 B (24.0%)**
- `## 6. Modo Ejecutivo de Backlog ("dame al PM")`: **1,660 B (19.1%)**
- `## 2. Principios Rectores de Ingeniería`: **1,614 B (18.6%)**
- `## 4. Modo de Entrada por Defecto (issue-refiner)`: **1,147 B (13.2%)**
- `## 5. Flujo de Trabajo en Git (issue-driven-workflow)`: **926 B (10.7%)**
- `## 3. Gobernanza de Decisiones (ADR / MADR)`: **644 B (7.4%)**
- `## 1. Modelo de Colaboración`: **564 B (6.5%)**

> **Observación:** El **67.0%** de `GEMINI.md` (secciones 4, 5, 6 y 7 = 5,819 bytes) corresponde a reglas de enrutamiento de backlog, PM y selección de modelos que se inyectan en cada turno de subagentes Implementadores y Reviewers que **no** toman decisiones de backlog ni orquestan lotes.

---

## 3. Focos de Fuga de Tokens Priorizados (Evidencia Verificada)

### Foco 1 (Crítico): Multiplicación de Subagentes `self` y Review Obligatorio para Tareas `N1` en Lotes
- **Evidencia:** En `Project-Manager-Agent/skill/project-manager/SKILL.md` (Pasos 2 y 3) y `prompts/staff_pm.md` (secciones 2.2 y 2.3), **toda** Issue del lote —sin distinguir `N1` de `N2`— dispara 2 subagentes `TypeName: "self"` (`Implementer` + `PR Staff Reviewer`).
- **Traza verificada (`679b41e2`):** La Issue #35 (`docs(usage): alinear documentación`, cambio documental `N1`) consumió:
  - Implementer (`2a6cc574`): 11 turnos, 54,443 uncached input, 331,983 cache read, 5,368 output.
  - PR-Reviewer (`db858257`): 10 turnos, 53,368 uncached input, 273,701 cache read, 3,154 output.
  - **Total solo para 1 Issue documental `N1` (sin contar al PM):** 21 turnos, **107,811 uncached input** y **605,684 cache read**.
- **Fuga:** Un subagente `PR-Reviewer` completo para un cambio trivial `N1` (docs, config, 1-file fix con checks locales pasando) duplica el costo por issue (~50K–110K uncached input y ~10 turnos adicionales).

### Foco 2 (Alto): Overhead Fijo por Turno (`~18.7K` tokens median) y `GEMINI.md` Monolítico
- **Evidencia:** La mediana de `step_index == 1` es **18,755 tokens** (y hasta **22,738 tokens** en repos ESO con `eso-addon-suite` + `eso-mcp-server`). En una sesión de 45 turnos (`679b41e2` padre), ese contexto base se re-procesa (vía `cache_read` + crecimiento incremental) en los 45 turnos del padre más los 83 turnos de los 8 hijos (**128 turnos** en total).
- **Fuga:**
  - `GEMINI.md` (8,694 B) incluye 5,819 B de reglas de PM/Refiner/Tabla de Modelos en cada turno de subagentes implementadores y reviewers.
  - Repos ESO cargan simultáneamente `eso-addon-suite/rules/AGENTS.md` (5,558 B) + `AGENTS.md` local (hasta 4,275 B) + `.agents/rules/*.md` (4,903 B) + schemas de `eso-mcp-server`.

### Foco 3 (Alto): Ceremonia Git/CLI Fragmentada en Múltiples Turnos y Falta de `pm-agent land`
- **Evidencia directa en trazas:**
  - En `PM-Parent` (`679b41e2`), integrar **cada** Issue aprobada toma **4 turnos consecutivos** cuando el contexto acumulado ya está entre 40K y 56K tokens:
    1. `git switch dev` (step 32)
    2. `gh pr merge 38 --squash --delete-branch` (step 35)
    3. `git pull --prune --ff-only` + `gh issue close 33 --reason completed` (step 37)
    4. `pm-agent gate ... --stage post-merge` (step 40)
    En 4 issues, esto son **16 turnos de pura plomería Git/GitHub** en el contexto más pesado del coordinador.
  - En `Implementer` (`2a6cc574`), **4 de 11 turnos** (36% de los turnos del subagente) son plomería final por la regla de no encadenar comandos de red con `&&`: `git fetch` (step 6), `git push` (step 33), `gh pr create` (step 36), `rm -f .commit_msg .pr_body` + `send_message` (step 38).
  - En las 100 sesiones recientes, `rm` fue el **3.º comando más ejecutado** (**81 veces**), casi exclusivamente para borrar `.commit_msg`, `.pr_body`, `.issue_body` y `/tmp/*.json`.

### Foco 4 (Medio-Alto): Duplicación entre `SKILL.md` y `prompts/staff_*.md` + Re-lecturas de Skills Pesados
- **Evidencia:**
  - `project-manager/SKILL.md` (7,764 B) y `prompts/staff_pm.md` (10,928 B) repiten casi íntegramente las mismas 3 fases, reglas de enrutamiento de modelos y comandos `gh`/`git`. Cuando el PM lee ambos (10 de 15 ejecuciones observadas), carga **18,692 B (~4,700 tokens)** de instrucciones redundantes.
  - `issue-driven-workflow/SKILL.md` pesa **13,316 B** (211 líneas) porque incluye la sección completa de Release `dev -> main` (50 líneas) que un subagente Implementer de Issue nunca ejecuta en Pasos 1–6. Fue leído **37 veces** en 100 sesiones.
  - En `Implementer` (`2a6cc574` step 16) y `PR-Reviewer` (`db858257` steps 10 y 15) se observaron **re-lecturas del mismo archivo en la misma sesión** (`ESOInventoryHelper.lua`, `usage.md`, `README.md`).

### Foco 5 (Medio): Re-ejecución Redundante de Tests y Volcado Completo de JSONs Intermedios
- **Evidencia:**
  - En un lote de 4 issues (`679b41e2`), la suite `luajit tests/run.lua` se ejecutó en cada Implementer (4x), de nuevo en cada PR-Reviewer (4x), de nuevo en `codebase-audit scan --run-checks` (1x) y además manualmente en el PM-Parent en el step 107 (1x) = **10 ejecuciones** para 4 issues secuenciales.
  - En `679b41e2` step 6, leer `/tmp/pm_inspect.json` completo inyectó **12,859 tokens sin cachear** en un solo turno del PM-Parent (porque el JSON incluye cuerpos enteros de issues + documentos de gobernanza).

### Foco 6 (Medio): Desalineación de Modelos y Variación de Costo por Modelo
- **Evidencia:**
  - 13 sesiones en `gemini-4-carbon-medium` procesaron **19.74M tokens** (promedio **1.52M/sesión** vs. **0.89M/sesión** en `hydrogen-medium`).
  - 4 sesiones en `claude-opus-5-5-low` (`8322d4cc` invocó 2 subagentes en `claude-opus-5-5-low` con `step1` de ~27.2K tokens).
  - La mayoría de subagentes usaron `Model: "inherit"` (54/65 = 83%): cuando la sesión padre arranca en `carbon-medium` o `hydrogen-tiered-high`, todos los subagentes heredan ese modelo superior aunque la issue sea `fast` si el coordinador no fuerza `Model: "flash"` explícitamente.

---

## 4. Propuesta Priorizada de Optimizaciones (Etapa 2)

> [!NOTE]
> Las estimaciones de ahorro de tokens son **estimaciones derivadas** basadas en los promedios medidos en la Sección 1 (`~53K` uncached / `~270K` cache_read / `~10` turnos por `PR-Reviewer`; `~16` turnos de plomería por lote de 4 issues en `PM-Parent`; `~18.7K` tokens base por turno). Se indica la base de cálculo en cada ítem.

| Prioridad | Mitigación Propuesta | Ahorro Estimado (ROI en Tokens) | Riesgo en Calidad | Veredicto |
| :---: | :--- | :--- | :---: | :--- |
| **P1** | **Fast-path para `N1` en `project-manager`:** Omitir subagente `pr-reviewer` en Issues `N1` cuando los checks locales (`tests` + `linter` + `git diff --stat`) pasen al 100%, o agrupar `N1` triviales; mantener `pr-reviewer` obligatorio solo para `N2` y `/goal` de alto riesgo. | **~35%–45% del costo de lote** (~50K–110K uncached + ~270K cache_read y ~10 turnos ahorrados por cada Issue `N1` del lote). | **Bajo** (los checks deterministas + `codebase-auditor` al cierre del lote siguen cubriendo regresiones). | **Aprobar primero** |
| **P2** | **Crear `pm-agent land <repo> --issue <id> --pr <pr_id>`:** Unificar en un único comando determinista `git switch dev` + `gh pr merge --squash --delete-branch` + `gh issue close` + `git pull --prune --ff-only` + `git branch -D` + validación `post-merge`. | **~12 turnos ahorrados por lote de 4 issues** (~30K–45K uncached + ~600K cache_read en `PM-Parent`). | **Nulo / Positivo** (reduce errores manuales de rama y elimina fragmentación por regla de `&&`). | **Aprobar primero** |
| **P3** | **Compactar `GEMINI.md` (de 8.7 KB a ~3.5–4.0 KB) y mover detalle de PM/Refiner/Tabla de Modelos a skills bajo demanda:** Dejar en `GEMINI.md` solo principios de ingeniería, regla Backlog-First (2 líneas), regla de ramas (2 líneas) y disparadores cortos. | **~1,100–1,300 tokens menos en `step1` de cada sesión/subagente** (~130K–160K tokens ahorrados por cada 120 turnos). | **Nulo** (las reglas detalladas viven en `project-manager`, `issue-refiner` y `issue-driven-workflow` cuando se activan). | **Aprobar** |
| **P4** | **Eliminar duplicación `SKILL.md` vs `prompts/staff_*.md` y mover `Release dev->main` fuera de `issue-driven-workflow/SKILL.md`:** Fusionar `staff_pm.md` dentro de `project-manager/SKILL.md` (o dejar `SKILL.md` como índice de <1.5 KB) y mover `dev -> main` a `references/operations-and-recovery.md`. | **~2,500–3,500 tokens uncached menos** cada vez que se activan PM o Implementer (37 + 15 lecturas en 100 sesiones). | **Nulo** (cero pérdida de instrucciones; solo elimina texto duplicado). | **Aprobar** |
| **P5** | **Resumen compacto en `pm-agent inspect` y `pr-review gather` (`--compact`):** Evitar volcar `governance_docs` completos o cuerpos largos repetidos si solo se necesitan metadatos (`Ceremony`, `Model`, `acceptance_criteria`, archivos). | **~6,000–10,000 tokens uncached menos** en Step 6 de `PM-Parent` (`12,859` → `~3,000`). | **Bajo** (el agente lee `docs/adr/` puntual solo si `adr_review_issues` no está vacío). | **Aprobar** |
| **P6** | **Enrutamiento estricto `Model: "flash"` para `fast` cuando el padre corre en `carbon`/`pro` + evitar `codebase-audit` redundante en lotes solo-`N1`:** Forzar en `project-manager` que `model_profile == "fast"` pase `Model: "flash"` explícito si el padre no está en Hydrogen, y omitir re-correr tests en `PM-Parent` tras `codebase-audit --run-checks`. | **Reducción de consumo de cuota `Carbon`/`Pro`** en subagentes mecánicos + **1–2 turnos menos** al cierre del lote. | **Bajo** (si rebota en review, mantiene escalado automático a `balanced`). | **Aprobar** |

---

## 5. Conclusión

El ecosistema actual tiene una base determinista sólida (`pm-agent`, `pr-review`, `codebase-audit`), pero paga un **impuesto fijo de orquestación muy alto por cada Issue** (~128 turnos y ~4.8M–5.1M tokens para 4 issues en `hydrogen-medium`) debido a:
1. Ejecutar el ciclo completo de **2 subagentes `self` + 4 turnos de plomería Git/GH** incluso para tareas `N1` triviales.
2. Inyectar **8.7 KB de `GEMINI.md`** (67% reglas de orquestación) y **~18.7K tokens base** en cada turno de subagente.
3. Duplicar instrucciones entre `SKILL.md` y `prompts/staff_*.md`, más archivos temporales `.commit_msg`/`.pr_body` que obligan a turnos extra de `write_file` y `rm -f`.

Aplicar **P1 + P2 + P3 + P4** en una segunda etapa de implementación permitiría recortar el consumo por lote en torno a **40%–55%** (estimado sobre la eliminación del 2.º subagente en `N1`, compactación de contexto base y unificación de `pm-agent land`) **sin relajar los checks deterministas ni la calidad en tareas `N2`**.
