; Halstead operators and operands, as km counts them: the keywords that
; direct the flow, the words that delimit blocks (`do`, `end`, `fn`) and
; the symbols are operators; names, numbers and atoms are operands.
; Definitions, directives and the names of documentation and typespec
; attributes count nothing, and neither do strings.
; Captures: @operator, @operand, and @skip, which cancels the operator
; or operand captured at the same node.

["do" "end" "fn" "after" "rescue" "catch" "else" "when" "and" "or" "not" "in" "not in"] @operator

["===" "!==" "<<<" ">>>" "<<~" "~>>" "<~>" "|||" "&&&" "^^^" "|>" "<>"
 "++" "--" "==" "!=" "=~" "<=" ">=" "&&" "||" "->" "<-" "=>" "::" ".." "//"
 "**" "<<" ">>" "~>" "<~" "\\\\" "+" "-" "*" "/" "|" "&" "^" "!" "<" ">"
 "=" ";" "," "." ":" "(" ")" "[" "]" "{" "}" "%" "@" "~"] @operator

; Control flow written as a call: `if`, `case`, `raise`, ...
((identifier) @operator
  (#any-of? @operator "if" "unless" "case" "cond" "with" "for" "receive" "try" "raise" "reraise" "throw"))

((identifier) @operand
  (#not-any-of? @operand
    "if" "unless" "case" "cond" "with" "for" "receive" "try" "raise" "reraise" "throw"
    "def" "defp" "defmodule" "defmacro" "defmacrop" "defstruct" "defprotocol" "defimpl"
    "defdelegate" "defguard" "defguardp" "defexception" "defoverridable" "alias" "import"
    "require" "use" "moduledoc" "doc" "spec" "type" "typep" "opaque" "callback"
    "macrocallback" "impl" "behaviour"))

[(alias) (integer) (float) (atom) (keyword) (char) (boolean) (nil)] @operand

; An interpolation opens with one token and closes with `}`.
"#{" @operator

; A sigil is a literal, as a string is: its delimiters are no operators.
(sigil ["~" "/" "|" "(" ")" "[" "]" "{" "}" "<" ">"] @skip)
