; Halstead operators and operands, as km counts them: the keywords that
; direct the flow, the boolean keywords and the symbols are operators;
; names and numbers are operands. Declarations, modifiers, contracts, the
; boolean literals and the built-in type names count nothing, and neither
; do strings and characters.
; Captures: @operator, @operand.

["if" "else" "match" "case" "when" "handle" "with" "and" "or" "not" "as"] @operator

; What a handler runs on the way in and out, and how its clauses resume.
["initially" "finally" "return"] @operator

; Openers the language writes as one token: a selective import, a map, a
; set, an attribute and an interpolation.
[".{" "%{" "%[" "#[" "#{"] @operator

["|>" "|?" "|!" "..." "++" "??" "==" "!=" "<=" ">=" ":=" "=>" "->" "||" ".."
 "+" "-" "*" "/" "%" "^" "|" "!" "<" ">" "=" ";" "," "." ":" "(" ")" "["
 "]" "{" "}" "@" "?" "&" "$"] @operator

(([(lower_identifier) (type_identifier)] @operand)
  (#not-any-of? @operand "Int" "Real" "Bool" "String" "Char" "Unit"))

[(integer_literal) (real_literal) "_"] @operand
