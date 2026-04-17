syn keyword notes contained TODO FIXME XXX NOTE

syn keyword nrBool true false

syn keyword nrType bool str fmtstr Field field
syn keyword nrType u8 u16 u32 u64 usize
syn keyword nrType i8 i16 i32 i64 isize

syn match nrType /\<[A-Z]\w*\>/

syn match nrOp '[+^\-\*/%#@&=<>|!?]'

syn match comment '//.*$' contains=notes,mlcmt
syn region mlcmt start='/\*' end='\*/' contains=notes
syn region nrAttribute start='#\[' end=']' contains=comment,mlcmt,nrFnCall,stringLiteral,charLiteral,integerLiteral,doubleLiteral,nrType

syn match nrAttribute '![a-z_]\w*'

syn match nrModule '\<[A-Z]\w*::'

syn keyword nrKeywords as assert assert_eq break call_data comptime constrain constrained
syn keyword nrKeywords continue contract crate dep dual else enum fn for global if impl in
syn keyword nrKeywords let loop match mod pub return return_data struct super trait type
syn keyword nrKeywords unchecked unconstrained unsafe use where while $crate

syn keyword nrModifiers mut

syn match nrFnCall '\w+('

syn region stringLiteral start='"' end='"'

syn match charLiteral '\'.\''
syn match charLiteral '\'\\.\''

syn match integerLiteral '\([A-Za-z0-9]\@<!\)[0-9_]\+\([ui]\(8\|16\|32\|64\)\)\?'
syn match integerLiteral '\([A-Za-z0-9]\@<!\)0b[01_]\+\([ui]\(8\|16\|32\|64\)\)\?'
syn match integerLiteral '\([A-Za-z0-9]\@<!\)0o[0-7_]\+\([ui]\(8\|16\|32\|64\)\)\?'
syn match integerLiteral '\([A-Za-z0-9]\@<!\)0x[0-9A-Fa-f_]\+\([ui]\(8\|16\|32\|64\)\)\?'

syn match doubleLiteral '\([A-Za-z0-9]\@<!\)\d\+\.\d*\(f\(16\|32\|64\)\)\?'

syn match nrFnCall /\w\+\s*(/me=e-1,he=e-1

let b:current_syntax = "nr"

hi def link notes          Todo
hi def link comment        Comment
hi def link mlcmt          Comment
hi def link nrAttribute    NoirAttribute
hi def link quote          PreProc
hi def link nrOp           Keyword
hi def link nrKeywords     Keyword
hi def link nrModifiers    Keyword
hi def link nrBool         Boolenr
hi def link nrFnCall       Function
hi def link nrModPath      ModPath
hi def link nrType         Type
hi def link stringLiteral  String
hi def link charLiteral    String
hi def link integerLiteral Number
hi def link doubleLiteral  Number

hi def link nrControl      ModPath
