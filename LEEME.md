# km2

Métricas de código sobre árboles de sintaxis: el sucesor de [km (Kimün)](https://github.com/lnds/kimun), escrito en [kaikai](https://github.com/lnds/kaikai) y que analiza con [tree-sitter](https://tree-sitter.github.io/).

km2 apunta a reemplazar a `km` sin cambios para quien lo usa: los mismos comandos, flags, formatos de salida, esquema JSON y `.kimun.toml`, con mejores mediciones donde un árbol de sintaxis ve lo que una lectura léxica no alcanza. Hasta llegar a la paridad, `km` sigue siendo la herramienta a usar.

Estado: `loc`, `indent`, `churn`, `age`, `authors` y `tc` están portados, con todas las opciones y formatos de sus pares en `km`. `cycom` está portado para Rust, Elixir y Kaikai, los lenguajes que km2 analiza, y `hal` para Rust; `km cycom` y `km hal` miden además una treintena de lenguajes que km2 deja fuera hasta incorporar sus gramáticas. Los demás comandos todavía no están implementados.

## Compilación

Requiere kaikai 0.201.3 (`.kaikai-version`), `km` y `jq` para el control de calidad, y `git` para `loc --by-author`, `churn`, `age` y `authors`.

```sh
make build   # ./km2
make test
make ci      # formato, lint, compilación, tests, control de calidad con km y km2, tests diferenciales contra km
make corpus  # el corpus de lenguajes: lo descarga y lo compara con km (red, varios GB)
```

El corpus de lenguajes, `tests/corpus/repos.tsv`, lista dos repositorios reales por lenguaje, cada uno fijado a un commit. `tools/corpus.sh` los clona en `~/.cache/km2-corpus` (`$KM2_CORPUS`), compara `loc` de cada uno con km y, con `files OWNER/REPO`, acota una diferencia hasta el archivo.

## km frente a km2

Cada valor que km2 informa distinto de `km` porque mide mejor, y por qué. Cada uno está fijado por un fixture en `fixtures/<comando>/differ`; `fixtures/<comando>/same` reúne lo que ambos informan igual.

| Comando | Campo | km | km2 | Razón |
|---|---|---|---|---|
| `cycom` | `complexity` | una rama por el `\|\|` de una clausura sin parámetros (`\|\| 0`) y por `&&` en un patrón o tipo de referencia (`\|&&b\|`, `&&str`) | ninguna | Ninguno es una decisión: el árbol distingue una clausura y una referencia de un operador booleano. |
| `cycom` | `functions` | una función por cada `fn` escrito en el cuerpo de un `macro_rules!` | ninguna; el cuerpo de la macro cuenta en `<file>` | El cuerpo de una macro es una plantilla, no una función del archivo. |
| `cycom` | `functions`, `complexity` | el cuerpo de una función cuya firma o cabeza ocupa varias líneas (cotas y `where` de Rust, un `= match f(` de kaikai con sus argumentos abajo) contado en `<file>` | contado en la función | El árbol da la extensión de la función, como sea que esté escrita. |
| `cycom` | `complexity` | ninguna rama por los brazos de un `match` en una función escrita en una línea | sus brazos | km omite la flecha que sigue a `fn` en su línea, una regla para las funciones anónimas de Elixir. |
| `cycom` | `complexity` | una rama por una palabra clave en el texto de un sigil de Elixir que interpola (`~s\|path for #{x}\|`) | ninguna | El texto de un sigil es un literal; solo se ejecuta lo que interpola. |
| `cycom` | `name` | `r` para una función nombrada con un identificador crudo (`r#async`) | `r#async` | El nombre como está escrito. |
| `cycom` | `name` | un nombre de Elixir sin su `?` o `!` (`valid`) | `valid?` | El nombre como está escrito. |
| `cycom` | `complexity` | ninguna rama por el código interpolado en un string de Elixir (`"#{a \|\| b}"`) | sus ramas | El código interpolado se ejecuta. La documentación (`@doc`, `@moduledoc`, `@typedoc`) sigue sin contar. |
| `cycom` | `complexity` | una cláusula de Elixir cuyo último patrón es `_` (`:exit, _ ->`) tomada por comodín | una rama | Solo una cláusula del patrón único `_` acepta cualquier valor. |
| `cycom` | `functions` | una declaración `extern` de kaikai en varias líneas como función, y las funciones de una línea que la siguen, perdidas | las funciones con cuerpo | Un `extern` no tiene cuerpo. |
| `hal` | `*_operators` | un `>>` donde cierran genéricos anidados (`Box<dyn Error>>`) | dos `>` | Cada `>` cierra un genérico; ninguno desplaza. |
| `hal` | `*_operators` | un `&&` en un tipo o patrón de referencia (`&&str`, `\|&&c\|`) y un `\|\|` por las barras de una clausura sin parámetros | dos `&`, dos `\|` | Ninguno es un operador booleano: el árbol distingue una referencia y una clausura de uno. |
| `hal` | `*_operators`, `*_operands` | un real partido en su punto o signo (`0.5`, `1e-6`: dos operandos y un operador) | un operando | Un real es un solo literal. |
| `hal` | `*_operands` | la `b` de un literal de bytes (`b'('`, `b"x"`) | ninguno, como para cualquier string o carácter | El prefijo es parte del literal. |
| `hal` | `*_operators`, `*_operands` | un identificador crudo leído como `r`, `#` y una palabra clave (`r#as`) | un operando | El nombre como está escrito. |
| `hal` | `*_operators`, `*_operands` | `macro_rules!` como operando y `!`; el `$self` de una macro como nada | nada por `macro_rules!`, como por `fn`; `$self` un operando | `macro_rules!` declara una macro; `$self` es una variable de macro, no `self`. |

## Brechas conocidas

Donde km2 todavía no se comporta como `km` porque a kaikai o a ahu le falta algo que necesita. Cada brecha está reportada aguas arriba y se cierra cuando sale la versión que la resuelve.

| Comportamiento | km | km2 | Aguas arriba |
|---|---|---|---|
| Un comando que falla (`--since 6x`, una ruta fuera de un repositorio) | `error: ...` | `Error: ...` | kaikailang-org/ahu#47 |
| `churn`, `age`: un renombre cerca del umbral de similitud del 50 % | lo sigue según puntúa libgit2 | lo sigue según puntúa `git log -M` | km2 lee la historia con el programa `git`; kaikai no tiene enlace a libgit2. En `lnds/kaikai`, difieren 5 de 879 archivos. |
| `authors`: `last_active` de un autor cuyos commits comparten la fecha de commit | la fecha de autor de un commit anterior (visto en `lnds/kimun` y `phoenixframework/phoenix`, un autor en cada uno) | la fecha de autor del commit más nuevo | El orden por fecha de libgit2 deja sin orden fijo los commits con la misma fecha de commit, así que km puede encontrar antes uno más antiguo. |
| Un elemento desconocido en un `--kind` separado por comas (`code,nope`) | `error: ...`, sale con 2 | `Error: ...`, sale con 1 | kaikailang-org/ahu#45 |
| `hal`: el separador de una repetición de macro (la `,` de `$($x),*`) | un operador | nada | tree-sitter-rust lee el separador como un token oculto, que ninguna consulta alcanza. |
