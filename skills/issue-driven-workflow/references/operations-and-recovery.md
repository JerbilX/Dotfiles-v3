# Operaciones Especiales: Aprovisionamiento, Code Review y Rollback

Procedimientos complementarios del skill `issue-driven-workflow` utilizando exclusivamente `git` y `gh` CLI nativos.

---

## 1. Aprovisionamiento de un Repositorio Nuevo

Cuando se inicie un proyecto que aún no tiene Git o aún no tiene su estructura remota:

1. **Inicialización Local (`main` + `dev`):**
   ```bash
   git init -b main
   git add <archivos-iniciales>
   git commit -m "chore: initial repository baseline"
   git branch -M main
   git checkout -b dev
   ```
2. **Confirmación antes de publicar en GitHub:**
   Preguntar siempre al usuario antes de crear el repositorio remoto. Tras su confirmación:
   ```bash
   gh repo create <nombre-repo> --private --source=. --remote=origin
   git push -u origin main
   git push -u origin dev
   gh repo edit --delete-branch-on-merge
   ```

---

## 2. Resolución de Observaciones en un Pull Request Abierto (Code Review)

Si antes de fusionar un PR el usuario pide ajustes o deja comentarios en el PR:
1. Trabajar **sobre la misma rama efímera del PR** (`git switch <rama-del-pr>` o `gh pr checkout <pr_id>`). No abrir una nueva rama ni una nueva issue.
2. Aplicar las correcciones con las herramientas nativas de archivos y ejecutar las validaciones/tests locales.
3. Realizar un nuevo commit descriptivo (`fix(<alcance>): ajustar según revisión en PR #<pr_id>`) y subirlo con `git push`.

---

## 3. Cierre de Tareas de Investigación / Spikes (Sin Cambios de Código)

Si una Issue tenía como único objetivo investigar, analizar o auditar algo y concluye que no requiere cambios de código:
1. Redactar las conclusiones técnicas en `.issue_comment`.
2. Publicar el informe en la Issue, cerrarla directamente y limpiar el archivo temporal:
   ```bash
   gh issue comment <issue_id> --body-file .issue_comment
   ```
   ```bash
   gh issue close <issue_id> --reason completed
   ```
   ```bash
   rm -f .issue_comment
   ```

---

## 4. Estrategia de Rollback y Recuperación

### Caso A: Revertir una tarea específica que introdujo un bug en `dev`
Como cada tarea entra a `dev` mediante `--squash`, cada Issue es **un único commit atómico** en el historial de `dev`. Para deshacerla limpiamente:
1. Crear rama de reversión desde `dev`:
   ```bash
   git fetch --prune origin
   git switch --no-track -c fix/revert-pr-<pr_id> origin/dev
   ```
2. Revertir el commit de squash sin abrir editor interactivo:
   ```bash
   git revert --no-commit <commit_sha>
   git commit -m "fix(revert): revert PR #<pr_id>"
   git push -u origin fix/revert-pr-<pr_id>
   ```
3. Abrir y fusionar el PR hacia `dev` y reabrir la Issue original (`gh issue reopen <issue_id>`) si debe rehacerse.
4. Si el PR revertido incluía un ADR nuevo, cambiar su frontmatter a `status: deprecated` con una breve nota explicativa.

### Caso B: Restauración Fuerte desde `main` o un Tag SemVer (`vX.Y.Z`)
Si el usuario desea comparar o restaurar el estado del proyecto a una versión estable previa congelada en `main`:
- Para inspeccionar diferencias contra la última versión estable: `git diff main..dev` (o `git diff vX.Y.Z..dev`).
- Cualquier acción que reescriba el historial de `dev` hacia un tag anterior requiere confirmación explícita del usuario.
