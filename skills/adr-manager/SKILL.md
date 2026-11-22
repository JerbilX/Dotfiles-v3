---
name: adr-manager
description: >-
  Manage, record, and consult Architecture Decision Records (ADRs) using the MADR (Markdown Architectural Decision Records) standard compatible with adr-tools. ACTIVATE this skill whenever proposing architectural changes, introducing or changing dependencies/libraries, modifying persistence engines or data schemas, refactoring core modules, evaluating technical tradeoffs, or documenting technical decisions. Operates 100% natively without external CLI dependencies.
---

# Architecture Decision Records (ADR) Manager

Guía operativa y protocolo para la consulta, detección de conflictos, redacción y ciclo de vida de Registros de Decisiones de Arquitectura (ADR) basados en el estándar **MADR (Markdown Architectural Decision Records)** y compatibles con la nomenclatura de **adr-tools**, operando de forma 100% nativa mediante herramientas de archivos del agente.

---

## 1. Principios Fundamentales

1. **Estándar MADR + adr-tools:** Estructura basada en Markdown con YAML frontmatter legible por máquina y estructurado para humanos. Compatible en nomenclatura con `adr-tools` (`docs/adr/NNNN-titulo-en-kebab-case.md`). Prohibido llevar bitácoras informales como `HISTORIAL.md`; las decisiones arquitectónicas se registran exclusivamente en `docs/adr/`.
2. **Operación 100% Nativa (Zero-CLI):** Queda **terminantemente prohibido** invocar herramientas de línea de comandos externas (como `adr-init`, `adr-new`, binarios de `adr-tools` o scripts bash equivalentes). Todas las operaciones de lectura, cálculo correlativo y escritura deben ejecutarse mediante las herramientas nativas de archivos del agente (listado, lectura, escritura y edición atómica).
3. **Inmutabilidad Histórica:** Una decisión registrada refleja el contexto y los trade-offs en el momento en que se tomó. Los ADRs históricos nunca se borran ni se reescriben en su cuerpo explicativo. Las modificaciones posteriores se gestionan mediante nuevos ADRs que reemplazan (`supersedes`) a los anteriores.
4. **Gate Humano de Aprobación:** El agente propone opciones y trade-offs, pero la aceptación definitiva de una decisión arquitectónica es prerrogativa exclusiva del Arquitecto (usuario).

---

## 2. Protocolo Operativo para el Agente

```text
[Pre-flight Check] --> ¿Existe docs/adr/?
        │
        ├── No ──> Si se requiere documentar una decisión arquitectónica, crear docs/adr/0001-*.md
        │
        └── Sí ──> Inspeccionar YAML frontmatters (status: accepted / rejected / superseded)
                     │
                     ├── ¿Conflicto detectado con decisión accepted?
                     │     └── [Stop & Warn] Detenerse y advertir al usuario antes de codificar.
                     │
                     └── ¿Se requiere nueva decisión arquitectónica?
                           └── [Creación Nativa] Redactar NNNN-*.md (proposed -> accepted tras aprobación humana)
```

### Fase 1: Consulta Previa (Pre-flight Check)

Antes de:
- Proponer cambios arquitectónicos estructurales.
- Introducir o sustituir librerías, frameworks o dependencias principales.
- Modificar motores de persistencia, almacenamiento (`SavedVariables`, SQL, cachés) o esquemas de datos.
- Refactorizar módulos centrales o contratos de interfaces críticas.

El agente **DEBE verificar proactivamente** si existe el directorio `docs/adr/` en la raíz del workspace activo:

1. Listar los archivos en `docs/adr/`.
2. Si existen ADRs, inspeccionar su YAML frontmatter (particularmente el campo `status`):
   - **`status: accepted`**: Lineamientos arquitectónicos vigentes y de cumplimiento obligatorio.
   - **`status: rejected`**: Enfoques previamente evaluados y descartados. No volver a proponer soluciones idénticas sin justificar qué condiciones cambiaron.
   - **`status: superseded by ADR-NNNN`**: La decisión ya no rige; consultar el ADR sucesor indicado.
3. Si se detecta un archivo `HISTORIAL.md` legacy en la raíz, no eliminarlo silenciosamente; consultar primero al usuario si desea retirarlo a favor de `docs/adr/`.

---

### Fase 2: Detección de Conflictos (Stop & Warn)

Si un requerimiento o cambio técnico planificado **entra en conflicto directo** con un ADR existente con `status: accepted`:

1. **Freno Inmediato:** No escribir código ni aplicar parches que vulneren la decisión aceptada.
2. **Advertencia Explícita:** Notificar el conflicto citando puntualmente el ADR relevante (ej. `ADR-0003` / `docs/adr/0003-nombre.md`):
   > *"He detectado un conflicto con la decisión arquitectónica vigente en ADR-0003 ('...'). El cambio planteado contradice la restricción acordada. ¿Deseas mantener ADR-0003 y adaptar la solución, o creamos un nuevo ADR para revocar y sustituir formalmente la decisión anterior?"*
3. **Punto de Sincronización:** Aguardar la decisión del usuario antes de proceder.

---

### Fase 3: Creación Compatible con `adr-tools` (I/O Nativo)

Cuando se acuerde entre el usuario y el agente documentar una nueva decisión:

1. **Cálculo Determinista del Correlativo:**
   - Inspeccionar los archivos existentes en `docs/adr/`.
   - Extraer el prefijo numérico de mayor valor (ej. si existen `0001-...` y `0002-...`, el siguiente es `0003`). Si no existen archivos, comenzar en `0001`.
2. **Nomenclatura Canónica:**
   - Formato exacto: `docs/adr/NNNN-titulo-en-kebab-case.md`
   - Reglas de título: Minúsculas, palabras separadas por guión medio (`-`), sin tildes, caracteres especiales ni espacios.
3. **Escritura Nativa:**
   - Leer la plantilla oficial en [resources/template.md](./resources/template.md).
   - Completar los campos y escribir el archivo en destino usando la herramienta nativa de escritura de archivos.

---

### Fase 4: Ciclo de Vida y Aprobación Humana

1. **Propuesta (`status: proposed`):**
   - Si el ADR se redacta como borrador exploratorio o propuesta pendiente de confirmación del usuario (en el chat o dentro de un plan de implementación aún no aprobado), nace con `status: proposed`.
2. **Aceptación (`status: accepted`):**
   - Cuando el usuario aprueba explícitamente la decisión arquitectónica o el plan de implementación asociado, el ADR se registra o actualiza a `status: accepted`.
   - Si el usuario ya aprobó la decisión durante la conversación previa y solicita directamente documentarla e implementarla, puede escribirse directamente con `status: accepted`.
3. **Descarte (`status: rejected`):**
   - Si tras analizar las opciones una propuesta completa se descarta y se desea dejar constancia para no repetir la discusión en el futuro, se registra con `status: rejected`.

---

### Fase 5: Reemplazo e Inmutabilidad (Superseding)

Cuando una nueva decisión técnica modifica, anula o sustituye una decisión previa:

1. **Inmutabilidad del Cuerpo:** Nunca eliminar ni modificar el contexto, opciones o consecuencias del ADR previo.
2. **Vinculación en el Nuevo ADR (`ADR-NNNN`):**
   - Declarar en el frontmatter del nuevo documento el archivo sustituido:
     ```yaml
     supersedes: ["0002-decision-anterior.md"]
     ```
3. **Actualización Atómica del ADR Reemplazado:**
   - Modificar **exclusivamente el YAML frontmatter** del ADR antiguo mediante edición nativa:
     ```yaml
     status: superseded by ADR-0005
     superseded-by: ["0005-nueva-decision.md"]
     ```

---

### Fase 6: Trazabilidad en Código

Al implementar código derivado de un ADR con `status: accepted`, agregar un comentario breve en el punto de entrada o módulo principal involucrado:
- En Lua: `-- Ref: docs/adr/NNNN-nombre-del-adr.md`
- En Python / Shell / YAML: `# Ref: docs/adr/NNNN-nombre-del-adr.md`
- En JS / TS / C# / SQL: `// Ref: docs/adr/NNNN-nombre-del-adr.md` o `-- Ref: docs/adr/NNNN-nombre-del-adr.md`

---

## 3. Especificación del YAML Frontmatter (MADR)

```yaml
---
status: proposed | accepted | rejected | superseded by ADR-NNNN | deprecated
date: YYYY-MM-DD
decision-makers: [JerbilX, Antigravity]
supersedes: []
superseded-by: []
---
```

| Estado | Significado y Política de Agente |
| :--- | :--- |
| `proposed` | Decisión en evaluación. No autoriza cambios arquitectónicos definitivos hasta su aprobación. |
| `accepted` | Decisión aprobada por el usuario. De cumplimiento obligatorio en todo desarrollo posterior. |
| `rejected` | Propuesta descartada. Documenta por qué no se adoptó para evitar reincidir en discusiones ya resueltas. |
| `superseded by ADR-NNNN` | Decisión revocada y sustituida por un ADR posterior. Conserva valor histórico pero no rige implementaciones actuales. |
| `deprecated` | Decisión que dejó de aplicar por cambios de entorno o eliminación de la funcionalidad, sin sustituto directo. |

---

## 4. Recursos Disponibles

- **Plantilla Oficial:** [resources/template.md](./resources/template.md). Utilizar siempre esta estructura MADR compacta para redactar nuevos ADRs.
