# Dotfiles-v3 — Entorno Base Declarativo y Multi-Dominio para Antigravity

Repositorio público de configuración declarativa, skills universales de gobernanza y catálogo de plugins por dominio para **Google Antigravity**, diseñado bajo el principio **YAGNI** (cero scripts de transpilación `build.sh`, cero carpetas `dist/` y cero symlinks manuales).

---

## 1. Filosofía y Decisiones Arquitectónicas ([ADR-0001](./docs/adr/0001-arquitectura-declarativa-multi-dominio.md))

1. **Separación de Responsabilidades por Repositorio:**
   - **`Dotfiles-v3`** almacena **exclusivamente artefactos declarativos**: directivas ejecutivas globales (`config/GEMINI.md`), registro declarativo de skills (`config/skills.json`), skills universales sin dependencias externas (`skills/`), catálogo de plugins por dominio (`plugins/`) y plantillas de proyecto (`templates/`).
   - Las herramientas con código fuente Python, CLIs y suites de pruebas unitarias viven en sus propios repositorios independientes.
2. **Aislamiento de Contexto por Dominio (Cero Contaminación entre Stacks):**
   - [`config/GEMINI.md`](./config/GEMINI.md) es **100% ejecutivo y agnóstico de stack tecnológico** (Modelo de colaboración Arquitecto + Staff Engineer, principios YAGNI/Modularidad/Verificación/Higiene en refactors, Gobernanza ADR y Flujo Git `issue-driven-workflow`).
   - Las reglas, servidores MCP y skills específicos de una tecnología (por ejemplo, Lua/EsoUI para *The Elder Scrolls Online*) se encapsulan en plugins de dominio dentro de [`plugins/`](./plugins/) y solo se cargan en los proyectos que los declaran explícitamente.
3. **Cero Symlinks — Registro Declarativo Nativo:**
   - Los skills globales se declaran con rutas portables `~/` en [`config/skills.json`](./config/skills.json) y `bootstrap.sh` las expande a `$HOME/` al aprovisionar `~/.gemini/config/skills.json` (sorteando la falta de expansión de `~/` en `fs.ParseAbsolutePath` del Language Server).
   - Cada proyecto activa únicamente los plugins de su dominio mediante su propio archivo `.agents/plugins.json` con `"path": "../Dotfiles-v3/plugins"` y filtrado `include_only`, incluyendo `Dotfiles-v3` en los `projectResources` del proyecto en Antigravity para satisfacer el confinamiento de raíces del workspace.

---

## 2. Ecosistema de Repositorios Públicos

| Repositorio | Rol en el Ecosistema | Integración con `Dotfiles-v3` |
| :--- | :--- | :--- |
| [**`JerbilX/Dotfiles-v3`**](https://github.com/JerbilX/Dotfiles-v3) | Núcleo declarativo global (`GEMINI.md`, `skills.json`), skills universales (`adr-manager`, `issue-driven-workflow`) y catálogo de plugins por dominio. | Repositorio base (`~/Proyectos-IA-V3/Dotfiles-v3`). |
| [**`JerbilX/Codebase-Auditor-Agent`**](https://github.com/JerbilX/Codebase-Auditor-Agent) | CLI en Python y skill de solo lectura (`codebase-auditor`) para auditorías deterministas de deuda técnica, LOC, deriva arquitectónica y violaciones de ADRs. | Registrado declarativamente en [`config/skills.json`](./config/skills.json) (`~/Proyectos-IA-V3/Codebase-Auditor-Agent/skill`). |
| [**`JerbilX/PR-Reviewer-Agent`**](https://github.com/JerbilX/PR-Reviewer-Agent) | CLI en Python y skill (`pr-reviewer`) para auditoría automatizada de Pull Requests con rúbrica Staff Software Engineer en GitHub. | Registrado declarativamente en [`config/skills.json`](./config/skills.json) (`~/Proyectos-IA-V3/PR-Reviewer-Agent/skill`). |
| [**`JerbilX/eso-mcp-server`**](https://github.com/JerbilX/eso-mcp-server) | Servidor MCP especializado en la API oficial de *The Elder Scrolls Online* (**EsoUI**), código fuente de ZOS, texturas, sonidos, linting estático y empaquetado. | Empaquetado como servidor MCP dentro del plugin [`plugins/eso-addon-suite`](./plugins/eso-addon-suite/). |
| [**`JerbilX/RPQuests`**](https://github.com/JerbilX/RPQuests) | Addon narrativo y de rol para *The Elder Scrolls Online* (**RPQuest**), consumidor de referencia del plugin `eso-addon-suite`. | Carga `eso-addon-suite` declarativamente mediante `.agents/plugins.json` (`include_only: ["eso-addon-suite"]`). |

---

## 3. Estructura del Repositorio

```text
Dotfiles-v3/
├── bootstrap.sh                      # Aprovisionamiento idempotente de ~/.gemini/config/
├── config/
│   ├── GEMINI.md                     # Núcleo ejecutivo global 100% agnóstico de stack
│   └── skills.json                   # Registro declarativo nativo de skills globales (~/)
├── docs/
│   └── adr/
│       └── 0001-arquitectura-declarativa-multi-dominio.md
├── plugins/
│   └── eso-addon-suite/              # Plugin de dominio para The Elder Scrolls Online (EsoUI)
│       ├── plugin.json               # Manifiesto del plugin
│       ├── mcp_config.json           # Conexión declarativa a eso-mcp-server
│       ├── rules/
│       │   └── AGENTS.md             # Reglas de compliance ESOUI / Baertram Addon Check
│       └── skills/
│           └── eso-addon-development/
│               ├── SKILL.md
│               └── references/
│                   ├── build-and-packaging.md
│                   └── lua-architecture.md
├── skills/
│   ├── adr-manager/                  # Gestión nativa de ADRs (estándar MADR / adr-tools)
│   │   ├── SKILL.md
│   │   └── resources/
│   │       └── template.md
│   └── issue-driven-workflow/        # Ciclo Git (dev -> main + SemVer Tags) y trazabilidad por Issues
│       ├── SKILL.md
│       └── references/
│           └── operations-and-recovery.md
└── templates/
    ├── plugins.json.example          # Ejemplo base de activación selectiva de plugins por proyecto
    └── eso-addon/
        └── .agents/
            └── plugins.json          # Plantilla lista para proyectos de addons de ESO
```

---

## 4. Aprovisionamiento Global (`bootstrap.sh`)

Para sincronizar de forma idempotente `~/.gemini/config/GEMINI.md` y `~/.gemini/config/skills.json` (limpiando cualquier `.git` embebido o symlinks legacy en `~/.gemini/config/skills/`):

```bash
./bootstrap.sh
```

---

## 5. Activación de Plugins por Dominio en Proyectos

Los plugins de [`plugins/`](./plugins/) **no se instalan globalmente** en `~/.gemini/config/plugins/` para evitar cargar servidores MCP y reglas de un dominio en proyectos de otro stack.

Para activar un plugin de dominio en un proyecto específico (por ejemplo, `eso-addon-suite` en un addon de ESO), incluye `Dotfiles-v3` en los `projectResources` del proyecto y copia la plantilla [`templates/eso-addon/.agents/plugins.json`](./templates/eso-addon/.agents/plugins.json) en `.agents/plugins.json` en la raíz del proyecto:

```json
{
  "entries": [
    {
      "path": "../Dotfiles-v3/plugins",
      "include_only": ["eso-addon-suite"]
    }
  ]
}
```
