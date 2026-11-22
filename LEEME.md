# km2

Métricas de código sobre árboles de sintaxis: el sucesor de [km (Kimün)](https://github.com/lnds/kimun), escrito en [kaikai](https://github.com/lnds/kaikai) y que analiza con [tree-sitter](https://tree-sitter.github.io/).

km2 apunta a reemplazar a `km` sin cambios para quien lo usa: los mismos comandos, flags, formatos de salida, esquema JSON y `.kimun.toml`, con mejores mediciones donde un árbol de sintaxis ve lo que una lectura léxica no alcanza. Hasta llegar a la paridad, `km` sigue siendo la herramienta a usar.

Estado: preparación. Todavía no hay comandos implementados; cada comando falla nombrándose.

## Compilación

Requiere kaikai 0.196.3 (`.kaikai-version`), y `km` y `jq` para el control de calidad.

```sh
make build   # ./km2
make test
make ci      # formato, lint, compilación, tests, control de calidad con km y km2
```

## km frente a km2

Cada valor que km2 informa distinto de `km`, y por qué. Vacía hasta portar el primer comando.

| Comando | Campo | km | km2 | Razón |
|---|---|---|---|---|
