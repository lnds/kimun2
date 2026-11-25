; Cyclomatic complexity, as km counts it: a branch per decision keyword,
; boolean operator and `??`. A `test` block counts with the code outside
; functions.
(function_declaration name: (lower_identifier) @name) @function

["if" "match" "case" "when" "handle" "with" "and" "or" "??"] @branch

; Top-level nodes: a file whose only ones are comments has no code.
(source_file (_) @item)

(source_file (line_comment) @comment)

; A `#[doc]` attribute is documentation, as a comment is.
((source_file (attribute name: (lower_identifier) @_doc) @comment)
  (#eq? @_doc "doc"))
