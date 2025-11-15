# 🚀 GUÍA COMPLETA DE GIT PARA RINDEGASTOV2

**Creado:** 14 de noviembre de 2025  
**Repositorio:** https://github.com/desarrollofundo-hash/rindegastov2.git  
**Colaboradores:** Josset (josset-dev) y Genry (genry-dev)

---

## 📌 TABLA DE CONTENIDOS

1. [Guía para Josset (josset-dev)](#para-ti-josset-dev)
2. [Guía para Genry (genry-dev)](#para-genry-genry-dev)
3. [Coordinación entre ustedes](#coordinación-entre-ustedes)
4. [Problemas comunes y soluciones](#problemas-comunes-y-soluciones)
5. [Configuración inicial](#configuración-inicial)
6. [Resumen de lo mínimo](#resumen-lo-mínimo-que-deben-hacer-diariamente)

---

## 📌 PARA TI (josset-dev)

### Inicio del día

```bash
git fetch origin                          # Actualizar referencias
git checkout josset-dev                   # Asegurar que estás en tu rama
git pull origin josset-dev                # Traer cambios remotos de tu rama
git merge origin/main                     # Sincronizarte con main
```

### Durante el trabajo

```bash
# Ver estado
git status

# Agregar cambios
git add .                                 # Agregar todos
# O selectivamente:
git add lib/archivo_especifico.dart

# Commitear
git commit -m "Descripción clara del cambio"

# Si necesitas ver cambios antes de commitear
git diff                                  # Ver cambios sin stagear
git diff --cached                         # Ver cambios ya stagados
```

### Antes de subir cambios

```bash
git fetch origin                          # Actualizar referencias
git pull origin josset-dev                # Traer cambios remotos
git merge origin/main                     # Sincronizarte con main (si hay cambios)
git push origin josset-dev                # Subir tus cambios
```

### Si hay conflictos

```bash
git status                                # Ver archivos en conflicto
# Editar archivos manualmente (resolver conflictos)
git add .
git commit -m "Resolver conflictos"
git push origin josset-dev
```

### Sincronización con cambios de Genry

```bash
git fetch origin
git merge origin/genry-dev                # Traer cambios de tu compañero
# Si hay conflictos, resolverlos
git push origin josset-dev
```

### Ver diferencias y commits

```bash
# Ver commits que estás adelante de main
git log origin/main..HEAD --oneline

# Ver diferencias con main
git diff origin/main..HEAD

# Ver diferencias con genry-dev
git diff origin/genry-dev..HEAD

# Ver historial visual
git log --graph --oneline --all

# Ver estado de ramas
git branch -vv
```

---

## 📌 PARA GENRY (genry-dev)

### Inicio del día

```bash
git fetch origin                          # Actualizar referencias
git checkout genry-dev                    # Asegurar que estás en tu rama
git pull origin genry-dev                 # Traer cambios remotos de tu rama
git merge origin/main                     # Sincronizarte con main
```

### Durante el trabajo

```bash
# Ver estado
git status

# Agregar cambios
git add .                                 # Agregar todos
# O selectivamente:
git add lib/archivo_especifico.dart

# Commitear
git commit -m "Descripción clara del cambio"

# Si necesitas ver cambios antes de commitear
git diff                                  # Ver cambios sin stagear
git diff --cached                         # Ver cambios ya stagados
```

### Antes de subir cambios

```bash
git fetch origin                          # Actualizar referencias
git pull origin genry-dev                 # Traer cambios remotos
git merge origin/main                     # Sincronizarte con main (si hay cambios)
git push origin genry-dev                 # Subir tus cambios
```

### Si hay conflictos

```bash
git status                                # Ver archivos en conflicto
# Editar archivos manualmente (resolver conflictos)
git add .
git commit -m "Resolver conflictos"
git push origin genry-dev
```

### Sincronización con cambios de Josset

```bash
git fetch origin
git merge origin/josset-dev               # Traer cambios de tu compañero
# Si hay conflictos, resolverlos
git push origin genry-dev
```

### Ver diferencias y commits

```bash
# Ver commits que estás adelante de main
git log origin/main..HEAD --oneline

# Ver diferencias con main
git diff origin/main..HEAD

# Ver diferencias con josset-dev
git diff origin/josset-dev..HEAD

# Ver historial visual
git log --graph --oneline --all

# Ver estado de ramas
git branch -vv
```

---

## 🔄 COORDINACIÓN ENTRE USTEDES

### Antes de trabajar en archivos similares

```bash
# JOSSET verifica qué cambios tiene GENRY
git fetch origin
git diff origin/genry-dev..HEAD -- lib/archivo_especifico.dart

# GENRY verifica qué cambios tiene JOSSET
git fetch origin
git diff origin/josset-dev..HEAD -- lib/archivo_especifico.dart
```

### Cuando ambos hacen cambios en el mismo archivo

```bash
# 1. El que termine primero hace push
git push origin su-rama

# 2. El otro hace merge antes de pushear
git fetch origin
git merge origin/otra-rama
# Resolver conflictos si los hay
git push origin su-rama
```

### Flujo recomendado de trabajo simultáneo

```bash
# MAÑANA - Ambos sincronizar
git fetch origin
git pull origin main
git checkout su-rama-respectiva
git merge origin/main

# DURANTE EL DÍA - Cada uno trabaja
git add .
git commit -m "Mensaje descriptivo"

# MEDIODÍA - Sincronización intermedia (recomendado)
git fetch origin
git pull origin su-rama-respectiva
git merge origin/otra-rama  # Ver cambios del compañero
git push origin su-rama-respectiva

# TARDE - Último push antes de terminar
git fetch origin
git pull origin su-rama-respectiva
git push origin su-rama-respectiva
```

---

## 📋 CHECKLIST DIARIO (AMBOS)

### ✅ MAÑANA

- [ ] `git fetch origin`
- [ ] `git pull origin main`
- [ ] `git checkout su-rama`
- [ ] `git merge origin/main`

### ✅ DURANTE EL DÍA

- [ ] `git add .`
- [ ] `git commit -m "Mensaje claro"`
- [ ] Antes de ir a comer/descanso: `git push origin su-rama`

### ✅ ANTES DE TERMINAR

- [ ] `git fetch origin`
- [ ] `git pull origin su-rama`
- [ ] `git merge origin/otra-rama` (ver cambios del compañero)
- [ ] `git push origin su-rama`

---

## 🆘 PROBLEMAS COMUNES Y SOLUCIONES

### Problema: "Rechazo de push porque hay cambios remotos"

```bash
# Solución:
git fetch origin
git pull origin su-rama
git push origin su-rama
```

### Problema: "Tengo cambios locales pero necesito traer cambios remotos"

```bash
# Opción 1: Commitear primero
git add .
git commit -m "Mensaje"
git pull origin su-rama
git push origin su-rama

# Opción 2: Stashear (guardar temporalmente)
git stash                     # Guardar cambios
git pull origin su-rama       # Traer cambios
git stash pop                 # Recuperar cambios (resolver conflictos si hay)
git add .
git commit -m "Mensaje"
git push origin su-rama
```

### Problema: "Mergeé accidentalmente cambios que no quería"

```bash
# Ver últimos commits
git log --oneline

# Deshacer último commit (pero mantener cambios)
git reset --soft HEAD~1

# O deshacer completamente
git reset --hard HEAD~1

# Si ya hiciste push (cuidado, solo si nadie más está usando la rama)
git push origin su-rama --force
```

### Problema: "Tengo conflictos en merge"

```bash
# Ver archivos en conflicto
git status

# Editar archivos manualmente
# (buscar <<<<<<, ======, >>>>>> en los archivos)

# O usar herramienta visual:
git mergetool

# Después de resolver:
git add .
git commit -m "Resolver conflictos"
git push origin su-rama
```

### Problema: "No recuerdo en qué rama estoy"

```bash
# Ver rama actual
git branch

# Ver rama actual y estado de todas
git branch -a

# Ver estado completo
git status
```

### Problema: "Quiero ver qué cambios hizo mi compañero"

```bash
# Ver commits de Genry que no estás
git log HEAD..origin/genry-dev --oneline

# Ver commits de Josset que no estás
git log HEAD..origin/josset-dev --oneline

# Ver archivos específicos que cambiaron
git diff origin/genry-dev..HEAD -- lib/nombre_archivo.dart
```

---

## 💡 CONFIGURACIÓN INICIAL (UNA SOLA VEZ)

```bash
# Configurar información personal
git config --global user.name "Tu Nombre"
git config --global user.email "tuemail@example.com"

# Configurar comportamiento seguro
git config --global pull.rebase false
git config --global fetch.prune true

# Ver configuración actual
git config --global -l
```

---

## 🎯 RESUMEN: Lo MÍNIMO que deben hacer diariamente

### JOSSET (josset-dev)

```bash
# Mañana
git fetch origin && git checkout josset-dev && git merge origin/main

# Durante el día
git add . && git commit -m "Descripción" && git push origin josset-dev

# Antes de terminar
git fetch origin && git merge origin/genry-dev && git push origin josset-dev
```

### GENRY (genry-dev)

```bash
# Mañana
git fetch origin && git checkout genry-dev && git merge origin/main

# Durante el día
git add . && git commit -m "Descripción" && git push origin genry-dev

# Antes de terminar
git fetch origin && git merge origin/josset-dev && git push origin genry-dev
```

---

## ❌ LO QUE NUNCA DEBEN HACER

```bash
# ❌ NO hacer force push sin consultar
git push --force origin su-rama

# ❌ NO commitear archivos generados automáticamente
# (Usar .gitignore)

# ❌ NO trabajar directamente en main
git checkout main

# ❌ NO mergear sin ver qué cambios traes
git merge sin revisar antes

# ❌ NO commitear cambios sin un mensaje claro
git commit -m "x"

# ❌ NO hacer git add . sin revisar qué estás agregando
# Mejor: git add archivo.dart (selectivamente)
```

---

## 📚 COMANDOS ÚTILES AVANZADOS

```bash
# Ver último commit de cada rama
git log --oneline -1 origin/main
git log --oneline -1 origin/josset-dev
git log --oneline -1 origin/genry-dev

# Ver cuántos commits te falta de main
git log origin/main..HEAD --oneline | wc -l

# Ver cambios sin hacer commit (stash)
git stash list                # Ver stashes guardados
git stash show stash@{0}      # Ver qué hay en el stash
git stash pop                 # Recuperar último stash
git stash drop                # Eliminar stash

# Cambiar commit anterior sin perder cambios
git commit --amend

# Ver quién hizo qué cambios en un archivo
git blame lib/archivo.dart

# Ver historial de cambios en un archivo
git log -p lib/archivo.dart

# Buscar cambios en commits anteriores
git log --grep="palabra clave" --oneline
```

---

## 🔗 REFERENCIAS RÁPIDAS

**Repositorio:** https://github.com/desarrollofundo-hash/rindegastov2.git

**Ramas principales:**

- `main` - Rama principal de producción
- `josset-dev` - Tu rama de desarrollo
- `genry-dev` - Rama de Genry

**Pull Requests:** https://github.com/desarrollofundo-hash/rindegastov2/pulls

---

## 📝 NOTAS FINALES

1. **Siempre sincroniza primero** antes de hacer cambios importantes
2. **Commitea frecuentemente** con mensajes claros
3. **Pushea regularmente** para no perder tu trabajo
4. **Coordínate con tu compañero** si trabajan en archivos similares
5. **Revisa antes de mergear** para evitar conflictos
6. **Usa .gitignore** para archivos generados automáticamente
7. **Nunca hagas force push** sin estar seguro de lo que haces

---

**Última actualización:** 14 de noviembre de 2025
