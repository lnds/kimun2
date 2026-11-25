# km2

Métricas de código sobre árboles de sintaxis: el sucesor de [km (Kimün)](https://github.com/lnds/kimun), escrito en [kaikai](https://github.com/lnds/kaikai) y que analiza con [tree-sitter](https://tree-sitter.github.io/).

km2 apunta a reemplazar a `km` sin cambios para quien lo usa: los mismos comandos, flags, formatos de salida, esquema JSON y `.kimun.toml`, con mejores mediciones donde un árbol de sintaxis ve lo que una lectura léxica no alcanza. Hasta llegar a la paridad, `km` sigue siendo la herramienta a usar.

Estado: `loc`, `indent`, `churn`, `age`, `authors` y `tc` están portados, con todas las opciones y formatos de sus pares en `km`. Los demás comandos todavía no están implementados.

## Compilación

Requiere kaikai 0.199.2 (`.kaikai-version`), `km` y `jq` para el control de calidad, y `git` para `loc --by-author`, `churn`, `age` y `authors`.

```sh
make build   # ./km2
make test
make ci      # formato, lint, compilación, tests, control de calidad con km y km2, tests diferenciales contra km
make corpus  # el corpus de lenguajes: lo descarga y lo compara con km (red, varios GB)
```

El corpus de lenguajes, `tests/corpus/repos.tsv`, lista dos repositorios reales por lenguaje, cada uno fijado a un commit. `tools/corpus.sh` los clona en `~/.cache/km2-corpus` (`$KM2_CORPUS`), compara `loc` de cada uno con km y, con `files OWNER/REPO`, acota una diferencia hasta el archivo.

## km frente a km2

Cada valor que km2 informa distinto de `km` porque mide mejor, y por qué. Ninguno por ahora: los comandos portados informan lo mismo que sus pares en `km`.

| Comando | Campo | km | km2 | Razón |
|---|---|---|---|---|

## Brechas conocidas

Donde km2 todavía no se comporta como `km` porque a kaikai o a ahu le falta algo que necesita. Cada brecha está reportada aguas arriba y se cierra cuando sale la versión que la resuelve.

| Comportamiento | km | km2 | Aguas arriba |
|---|---|---|---|
| Una línea cuyo único contenido es un byte UTF-8 inválido que kaikai decodifica como espacio (un `0x85` suelto, un `0xE9` truncado) | código | en blanco | lnds/kaikai#3555 |
| Un comando que falla (`--since 6x`, una ruta fuera de un repositorio) | `error: ...` | `Error: ...` | kaikailang-org/ahu#47 |
| `churn`, `age`: un renombre cerca del umbral de similitud del 50 % | lo sigue según puntúa libgit2 | lo sigue según puntúa `git log -M` | km2 lee la historia con el programa `git`; kaikai no tiene enlace a libgit2. En `lnds/kaikai`, difieren 5 de 879 archivos. |
| `authors`: `last_active` de un autor cuyos commits comparten la fecha de commit | la fecha de autor de un commit anterior (visto en `lnds/kimun` y `phoenixframework/phoenix`, un autor en cada uno) | la fecha de autor del commit más nuevo | El orden por fecha de libgit2 deja sin orden fijo los commits con la misma fecha de commit, así que km puede encontrar antes uno más antiguo. |
| Un directorio que no se puede leer | avisa, con el código de error del sistema | avisa, sin el código | lnds/kaikai#3535 |
| Un archivo que no se puede leer | `<ruta>: Permission denied (os error 13)` | `<ruta>: read_file: cannot open file` | lnds/kaikai#3535 |
| Un elemento desconocido en un `--kind` separado por comas (`code,nope`) | `error: ...`, sale con 2 | `Error: ...`, sale con 1 | kaikailang-org/ahu#45 |
