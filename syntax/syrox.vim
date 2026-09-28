if exists('b:current_syntax')
  finish
endif

syntax case match
syntax keyword syroxKeyword pub mod use inputs outputs type struct enum resource value opaque owner once let where in
syntax keyword syroxControl match compare
syntax keyword syroxBuiltin memoize module_exports erase fold
syntax keyword syroxPrimitive int str
syntax keyword syroxSelf self
syntax match syroxType '\<[A-Z][A-Za-z0-9_]*\>'
syntax match syroxFunction '\<[a-z_][A-Za-z0-9_]*\ze\s*('
syntax match syroxNamespace '\<[A-Za-z_][A-Za-z0-9_]*\ze\s*::'
syntax keyword syroxFn fn nextgroup=syroxFunctionName skipwhite
syntax match syroxFunctionName '[A-Za-z_][A-Za-z0-9_]*' contained
syntax match syroxNumber '\<[0-9]\+\>'
syntax match syroxOperator '::\|->\|=>\|++\|\.\.='
syntax match syroxOperator '[=<>]\|\.\.'
syntax match syroxDelimiter '[{}()[\],;:]'
syntax region syroxString start=+"+ skip=+\\.+ end=+"+ oneline contains=syroxEscape,syroxInterpolation
syntax match syroxEscape +\\["\\nrt$]+ contained
syntax region syroxInterpolation start='${' end='}' contained oneline
syntax keyword syroxTodo TODO FIXME XXX NOTE contained
syntax match syroxComment '//.*$' contains=syroxTodo,@Spell

highlight default link syroxKeyword Keyword
highlight default link syroxControl Conditional
highlight default link syroxBuiltin Function
highlight default link syroxPrimitive Type
highlight default link syroxSelf Identifier
highlight default link syroxType Type
highlight default link syroxFunction Function
highlight default link syroxFunctionName Function
highlight default link syroxFn Keyword
highlight default link syroxNamespace Include
highlight default link syroxNumber Number
highlight default link syroxOperator Operator
highlight default link syroxDelimiter Delimiter
highlight default link syroxString String
highlight default link syroxEscape SpecialChar
highlight default link syroxInterpolation Special
highlight default link syroxComment Comment
highlight default link syroxTodo Todo

let b:current_syntax = 'syrox'
