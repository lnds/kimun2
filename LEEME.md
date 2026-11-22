# km2

Métricas de código sobre árboles de sintaxis: el sucesor de [km (Kimün)](https://github.com/lnds/kimun), escrito en [kaikai](https://github.com/lnds/kaikai) y que analiza con [tree-sitter](https://tree-sitter.github.io/).

km2 apunta a reemplazar a `km` sin cambios para quien lo usa: los mismos comandos, flags, formatos de salida, esquema JSON y `.kimun.toml`, con mejores mediciones donde un árbol de sintaxis ve lo que una lectura léxica no alcanza. Hasta llegar a la paridad, `km` sigue siendo la herramienta a usar.

Estado: `loc` está portado, con todas las opciones y formatos de `km loc`. Los demás comandos todavía no están implementados.

## Compilación

Requiere kaikai 0.196.3 (`.kaikai-version`), `km` y `jq` para el control de calidad, y `git` para `loc --by-author`.

```sh
make build   # ./km2
make test
make ci      # formato, lint, compilación, tests, control de calidad con km y km2, tests diferenciales contra km
```

## km frente a km2

Cada valor que km2 informa distinto de `km` porque mide mejor, y por qué. Ninguno por ahora: `loc` informa lo mismo que `km loc`.

| Comando | Campo | km | km2 | Razón |
|---|---|---|---|---|

## Brechas conocidas

Donde km2 todavía no se comporta como `km` porque a kaikai o a ahu le falta algo que necesita. Cada brecha está reportada aguas arriba y se cierra cuando sale la versión que la resuelve.

| Comportamiento | km | km2 | Aguas arriba |
|---|---|---|---|
| Formato del JSON | con sangría | compacto (mismo contenido) | lnds/kaikai#3521 |
| Una línea con solo espacios no ASCII (U+00A0, U+3000), `\v` o `\f` | en blanco | código | lnds/kaikai#3512 |
| Recorrer un árbol ignorado (`target/`, `node_modules/`) | no se recorre | se lista y luego se filtra: mismo resultado, más lento | lnds/kaikai#3511 |
| Un directorio que no se puede leer | avisa | se omite en silencio | lnds/kaikai#3511 |
| Una raíz a la que se llega por un enlace simbólico o por `..` | se resuelve a su ruta real | se resuelve por nombre | lnds/kaikai#3516 |
| Errores de uso (valor inválido, opciones en conflicto) | `error: ...`, sale con 2 | `Error: ...`, sale con 1 | kaikailang-org/ahu#37 |
| Opción corta de versión | `-V` | `-v` | kaikailang-org/ahu#38 |
| `--by-author` sin el programa `git` | recurre a libgit2 | necesita `git` | ninguna: kaikai no tiene binding de libgit2 |
