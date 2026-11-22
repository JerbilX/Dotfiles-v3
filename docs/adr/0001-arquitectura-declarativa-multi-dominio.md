---
status: accepted
date: 2026-11-22
decision-makers: [JerbilX, Antigravity]
supersedes: []
superseded-by: []
---

# 0001 - Arquitectura Declarativa Multi-Dominio y Registro Nativo sin Symlinks

## Contexto y Planteamiento del Problema
La configuración global previa en `~/.gemini/config/` mezclaba directivas ejecutivas universales (colaboración Arquitecto + Staff Engineer, YAGNI, ADRs y flujo Git) con reglas específicas de un único dominio (*The Elder Scrolls Online* / EsoUI), provocando contaminación de contexto al trabajar en proyectos de otros stacks (Python, web, servidores MCP). Además, la vinculación de skills externos dependía de symlinks manuales en `~/.gemini/config/skills/` y de un repositorio Git incrustado dentro del propio directorio de estado efímero del IDE (`~/.gemini/config/.git`).

## Impulsores de la Decisión (Decision Drivers)
* **Aislamiento de contexto por dominio:** Evitar inyectar reglas de un stack específico (ej. Lua/EsoUI) en proyectos de otros dominios.
* **Cero sobreingeniería:** Prescindir de scripts de compilación (`build.sh`), carpetas `dist/` o gestores de symlinks manuales.
* **Separación clara entre configuración declarativa y código fuente:** Mantener las herramientas con runtime Python y suites de tests en sus propios repositorios independientes.
* **Mecanismos nativos de Antigravity:** Aprovechar `skills.json` y `plugins.json` con rutas `~/` y filtrado `include_only`.

## Opciones Consideradas
* **Opción 1: Repositorio Git directo en `~/.gemini/config/` con symlinks manuales y `GEMINI.md` monolítico**
  * *Pro:* Configuración en una sola carpeta local.
  * *Contra:* Contamina todos los workspaces con reglas de dominios ajenos, requiere mantener `.gitignore` sobre archivos internos del IDE (`config.json`, `projects/`) y depende de symlinks frágiles.
* **Opción 2: Monorepo con scripts de build/transpilación de prompts (`build.sh` + `dist/`)**
  * *Pro:* Permite ensamblar perfiles a medida.
  * *Contra:* Introduce sobreingeniería innecesaria cuando Antigravity ya soporta carga jerárquica, `skills.json` y `plugins.json` nativos.
* **Opción 3: Repositorio declarativo `Dotfiles-v3` con núcleo global agnóstico, catálogo de plugins por dominio y registro nativo vía `skills.json` / `plugins.json`**
  * *Pro:* `GEMINI.md` queda 100% ejecutivo y agnóstico; los skills globales se registran declarativamente con `~/`; cada proyecto selecciona sus plugins de dominio mediante `.agents/plugins.json` (`include_only`).
  * *Contra:* Requiere un `bootstrap.sh` mínimo e idempotente para sincronizar `config/GEMINI.md` y `config/skills.json` hacia `~/.gemini/config/`.

## Decisión Adoptada
Opción elegida: **"Opción 3: Repositorio declarativo `Dotfiles-v3` con núcleo global agnóstico, catálogo de plugins por dominio y registro nativo vía `skills.json` / `plugins.json`"**, porque garantiza aislamiento total entre dominios, elimina los symlinks manuales y respeta estrictamente el principio YAGNI usando las capacidades nativas del sistema de personalización de Antigravity.

### Consecuencias
* **Positivas:**
  * Cero contaminación de tokens o reglas de ESO/Lua cuando se trabaja en repositorios Python u otros stacks.
  * Separación limpia de responsabilidades: `Dotfiles-v3` contiene solo artefactos declarativos, mientras que `Codebase-Auditor-Agent`, `PR-Reviewer-Agent` y `eso-mcp-server` evolucionan con su propio ciclo de tests e issues.
  * Activación de plugins de dominio 100% declarativa por proyecto mediante `.agents/plugins.json`.
* **Negativas / Trade-offs:**
  * Los proyectos deben declarar `.agents/plugins.json` (facilitado mediante `templates/`) para activar los plugins específicos de su dominio.
