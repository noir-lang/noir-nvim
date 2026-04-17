; Noir highlights query.
;
; Targets only the standard nvim-treesitter capture group set so upstream
; maintainers (and any stock colorscheme) can render Noir out of the box.
; Aztec-specific captures are deliberately omitted; they are scoped to a
; follow-up PR and/or the companion plugin.
;
; Capture ordering: the generic fallbacks come first so that more specific
; patterns below override them. Tree-sitter applies later matches at the
; same node position, so "specific wins over generic" only holds when the
; specific rule appears later in this file.

; ---------------------------------------------------------------- identifiers
(identifier) @variable

; -------------------------------------------------------------------- comments
(line_comment) @comment
(block_comment) @comment
(doc_comment) @comment.documentation
(inner_doc_style) @comment.documentation
(outer_doc_style) @comment.documentation

; -------------------------------------------------------------------- literals
(bool_literal) @boolean
(int_literal) @number
(str_literal) @string
(raw_str_literal) @string
(fmt_str_literal) @string
(str_content) @string
(escape_sequence) @string

; --------------------------------------------------------------------- types
(primitive_type) @type.builtin

; Explicit type-position matches: any identifier sitting in a `type:` field
; is a type reference regardless of capitalization.
(struct_field_item type: (identifier) @type)
(parameter type: (identifier) @type)
(return_type type: (identifier) @type)
(let_statement type: (identifier) @type)
(global_item type: (identifier) @type)
(trait_impl_type alias: (identifier) @type)
(type_item type: (identifier) @type)
(cast_expression type: (identifier) @type)
(trait_constant type: (identifier) @type)
(constrained_type type: (identifier) @type)
(where_constraint type: (identifier) @type)
(visible_type (identifier) @type)

; Generic type arguments and bounds.
(generic trait: (identifier) @type)
(generic type_parameters: (type_parameters (identifier) @type))
(type_parameters (identifier) @type)
(associated_type type: (identifier) @type)
(impl_item type: (identifier) @type)
(impl_item trait: (identifier) @type)

; Capitalized identifiers as type-ish fallback (PascalCase convention).
((identifier) @type
 (#match? @type "^[A-Z]"))

; Constant convention: SHOUTY_SNAKE_CASE.
((identifier) @variable
 (#match? @variable "^[A-Z][A-Z0-9_]+$"))

; --------------------------------------------------------------- declarations
(function_item name: (identifier) @function)
(function_signature_item name: (identifier) @function)
(struct_item name: (identifier) @type)
(trait_item name: (identifier) @type)
(type_item name: (identifier) @type)
(trait_impl_type name: (identifier) @type)
(trait_type name: (identifier) @type)
(module_or_contract_item name: (identifier) @module)
(global_item name: (identifier) @variable)

; ------------------------------------------------------------------ bindings
(parameter pattern: (identifier) @variable.parameter)
(parameter pattern: (mut_pattern (identifier) @variable.parameter))
(lambda_parameters (parameter pattern: (identifier) @variable.parameter))
(for_statement value: (identifier) @variable)
(let_statement pattern: (identifier) @variable)
(let_statement pattern: (mut_pattern (identifier) @variable))

; -------------------------------------------------------------------- paths
; Scope components of a path: everything to the left of `::` is module-ish
; *only* when the segment follows snake_case convention. PascalCase scopes
; are type prefixes (e.g. `T::zero()`, `FieldCompressedString::from_string`),
; so they're handled by the @type override that follows.
((path scope: (identifier) @module)
 (#match? @module "^[a-z_]"))
((path scope: (path name: (identifier) @module))
 (#match? @module "^[a-z_]"))
((path scope: (identifier) @type)
 (#match? @type "^[A-Z]"))
((path scope: (path name: (identifier) @type))
 (#match? @type "^[A-Z]"))

; -------------------------------------------------------------------- imports
; Terminal segments of a `use` path and items inside a `use ... { ... }` list
; otherwise fall through to the generic @variable rule, which leaves imports
; visually identical to local bindings. Treat them as @namespace by default;
; the PascalCase overrides promote type imports (e.g. `AztecAddress`) back to
; @type, and direct use of call expressions still wins for macro-like names.
(use_item decl: (path name: (identifier) @namespace))
(use_list (identifier) @namespace)
(use_list (path name: (identifier) @namespace))
((use_item decl: (path name: (identifier) @type))
 (#match? @type "^[A-Z]"))
((use_list (identifier) @type)
 (#match? @type "^[A-Z]"))
((use_list (path name: (identifier) @type))
 (#match? @type "^[A-Z]"))

; ---------------------------------------------------------------- properties
(struct_field_item name: (identifier) @property)
(struct_pattern_field (identifier) @property)
(field_initializer field: (identifier) @property)
(associated_type name: (identifier) @property)
(access_expression name: (identifier) @property)
(access_expression name: (int_literal) @property)

; ----------------------------------------------------------------- functions
; Direct call: foo(..)
(call_expression
  function: (identifier) @function)

; Qualified call: a::b::foo(..). The final segment is the call target.
(call_expression
  function: (path name: (identifier) @function))

; Method call: x.foo(..). Override the @property capture above.
(call_expression
  function: (access_expression
             name: (identifier) @function.method))

; Generic / turbofish calls: foo::<T>(..) and x.foo::<T>(..)
(call_expression
  function: (generic_function
             function: (identifier) @function))
(call_expression
  function: (generic_function
             function: (access_expression
                        name: (identifier) @function.method)))

; Constructors: Foo { .. }
(struct_expression name: (identifier) @type)
(struct_expression name: (path name: (identifier) @type))

; ----------------------------------------------------------------- attributes
; The outer capture styles the whole `#[...]` span. The inner `(content)`
; capture gives the attribute name its own direct hit, useful for
; colorschemes that style attribute names specifically and for `:Inspect`
; at the cursor, which only reports captures on the innermost node.
(attribute_item) @attribute
(attribute_item (content) @attribute)

; ----------------------------------------------------------------- operators
(binary_expression operator: _ @operator)

[
 "="
 "+="
 "-="
 "*="
 "/="
 "%="
 "&="
 "^="
 "<<="
 "|="
 ">>="
 "->"
 ".."
] @operator

; ----------------------------------------------------------------- punctuation
[ "," ";" "::" ":" "." ] @punctuation.delimiter
[ "(" ")" "[" "]" "{" "}" ] @punctuation.bracket

; ----------------------------------------------------------------- keywords
"fn" @keyword.function

[
 "mod"
 "contract"
 "struct"
 "trait"
 "impl"
 "type"
 "use"
 "global"
 "where"
 "quote"
 "unsafe"
 "comptime"
] @keyword

[
 "let"
 "break"
 "continue"
] @keyword

"return" @keyword

[
 "if"
 "else"
] @keyword

[
 "for"
 "in"
] @keyword

"as" @keyword

[
 "mut"
 "pub"
 "unconstrained"
] @keyword.modifier

[
 "call_data"
 "return_data"
] @keyword

; Path kinds.
[
 (super)
 (crate)
 (dep)
] @module

(self) @variable
(mutable_modifier) @keyword.modifier

; Bare `self` in receiver / scope positions is parsed as a generic
; `(identifier)` rather than the dedicated `(self)` node, so the generic
; @variable rule wins. Keep it explicitly captured as a variable.
((identifier) @variable
 (#eq? @variable "self"))

; Built-in pseudo-functions: `assert` / `assert_eq` are keyword-like in the
; grammar (constrain_statement), so highlight them as builtin functions.
(constrain_statement ["assert" "assert_eq"] @function)
