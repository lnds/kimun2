; Cyclomatic complexity, as km counts it: a branch per decision keyword
; and short-circuit operator, macro arguments included, and one per match
; arm but the catch-all. Nested functions and closures count in the
; function that holds them.
(function_item name: (identifier) @name) @function

["if" "while" "for" "loop" "&&" "||" "=>"] @branch

; `impl Trait for Type` names a type; `for` there is no loop.
(impl_item "for" @unbranch)

((match_arm pattern: (match_pattern) @unbranch)
  (#eq? @unbranch "_"))

; Top-level nodes: a file whose only ones are comments has no code.
(source_file (_) @item)

(source_file [(line_comment) (block_comment)] @comment)
