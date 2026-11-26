; Halstead operators and operands, as km counts them: control-flow
; keywords and symbols are operators; names and numbers are operands.
; Declarations, modifiers and the built-in type names count nothing, and
; neither do string and character literals.
; Captures: @operator, @operand.

["if" "else" "match" "for" "while" "loop" "return" "break" "continue" "as" "in"] @operator

["..=" "..." "=>" "->" "&&" "||" "==" "!=" "<=" ">=" "+=" "-=" "*=" "/=" "%="
 "&=" "|=" "^=" "<<=" ">>=" "<<" ">>" "::" ".." "+" "-" "*" "/" "%" "&" "|"
 "^" "!" "<" ">" "=" ";" "," "." ":" "(" ")" "[" "]" "{" "}" "?" "#"] @operator

; A macro's arguments are tokens: a keyword there is an identifier.
((identifier) @operator
  (#any-of? @operator "if" "else" "match" "for" "while" "loop" "return" "break" "continue" "as" "in"))

(([(identifier) (field_identifier) (shorthand_field_identifier) (type_identifier)] @operand)
  (#not-any-of? @operand
    "if" "else" "match" "for" "while" "loop" "return" "break" "continue" "as" "in"
    "fn" "let" "mut" "const" "static" "extern" "unsafe" "async" "await" "move" "ref"
    "impl" "struct" "enum" "trait" "type" "use" "mod" "where" "pub" "crate" "super"
    "self" "Self" "dyn" "i8" "i16" "i32" "i64" "i128" "isize" "u8" "u16" "u32"
    "u64" "u128" "usize" "f32" "f64" "bool" "char" "str" "String" "Vec" "Option"
    "Result" "Box"))

[(integer_literal) (float_literal) (boolean_literal) "_"] @operand

; Words the grammar reserves that read as names: `default` (`::default()`,
; `#[serde(default)]`), a macro's `$name` and its fragment specifiers.
["default" "union" "raw" "gen" "try" "yield"] @operand

; The separator of a macro repetition, as the `,` of `$($x),*`.
(repetition_separator) @operator

((metavariable) @operand (#not-eq? @operand "$crate"))

(fragment_specifier) @operand
