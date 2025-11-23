" Syntax highlighting for luca chat buffers

if exists("b:current_syntax")
  finish
endif

syntax match LucaUser /^👤 .*/
syntax match LucaAssistant /^🤖 .*/
syntax match LucaSeparator /^=== .* ===$/
syntax match LucaCodeBlock /```.*```/

highlight default link LucaUser Identifier
highlight default link LucaAssistant Function
highlight default link LucaSeparator Comment
highlight default link LucaCodeBlock String

let b:current_syntax = "luca-chat"

