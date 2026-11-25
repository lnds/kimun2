; Cyclomatic complexity, as km counts it: a branch per decision construct
; and boolean operator, and one per clause arrow but the catch-all and
; the arrow of an anonymous function opened on its line. Each clause of
; a `def` is a function.
((call
  target: (identifier) @_def
  (arguments
    [(call target: (identifier) @name)
     (identifier) @name
     (binary_operator left: [(call target: (identifier) @name) (identifier) @name])])) @function
  (#any-of? @_def "def" "defp" "defmacro" "defmacrop"))

((call target: (identifier) @branch)
  (#any-of? @branch "if" "unless" "with" "for"))

["and" "or" "&&" "||" "rescue" "catch"] @branch

"->" @arrow

((stab_clause left: (arguments . (identifier) @_catch_all .) "->" @unarrow)
  (#eq? @_catch_all "_"))

(anonymous_function "fn" @lambda)

; A `quote` is code for the caller to compile: it counts in no function
; around it, and each `def` inside it is a function of its own.
((call target: (identifier) @_quote) @scope
  (#eq? @_quote "quote"))

; Documentation is no code, whatever it interpolates.
((unary_operator operand: (call target: (identifier) @_attr)) @ignore
  (#any-of? @_attr "doc" "moduledoc" "typedoc"))

; Top-level nodes: a file whose only ones are comments has no code.
(source (_) @item)

(source (comment) @comment)
