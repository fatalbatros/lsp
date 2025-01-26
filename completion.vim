function Completion() abort
  call ForceSync()
  let l:request = {
      \'method': 'textDocument/completion',
      \'params': {
      \   'textDocument': {'uri': 'file://' . expand("%:p")},
      \   'position': {'line': getpos('.')[1]-1,'character': getpos('.')[2]},
      \   'context': { 'triggerKind': 1 },
      \ },
  \ }
"  call ch_sendexpr(g:lsp[&filetype]['channel'],l:request,{'callback':'s:CompletionCallback'})
" 
  "ch_evalexpr waits for the response. A timeout can be set in opt
  let g:comple = ch_evalexpr(g:lsp[&filetype]['channel'], l:request, {})
  "There is a field isComplete that I am ignoring, I thinks it is for the case
  "that the callback is not complete.
  return g:comple['result']['items']
endfunction 

set <A-z>=z
imap <A-z> :call Completion()<CR>
set completeopt= 
set omnifunc=OmniLsp

function! OmniLsp(findstart, base ) abort
  if a:findstart | return col('.') | else
  
  let l:data = Completion()
  let l:list = []
  for i in l:data
    let l:item = {
          \'word': trim(i['textEdit']['newText']),
          \'menu': '[' . s:completion__kinds[i['kind']] . ']',
          \'info': 'Work In Progress',
          \}
    call add(l:list, l:item )
  endfor
  return l:list
endfunction


let s:completion__kinds = {
            \ '1': 'text',
            \ '2': 'method',
            \ '3': 'function',
            \ '4': 'constructor',
            \ '5': 'field',
            \ '6': 'variable',
            \ '7': 'class',
            \ '8': 'interface',
            \ '9': 'module',
            \ '10': 'property',
            \ '11': 'unit',
            \ '12': 'value',
            \ '13': 'enum',
            \ '14': 'keyword',
            \ '15': 'snippet',
            \ '16': 'color',
            \ '17': 'file',
            \ '18': 'reference',
            \ '19': 'folder',
            \ '20': 'enum member',
            \ '21': 'constant',
            \ '22': 'struct',
            \ '23': 'event',
            \ '24': 'operator',
            \ '25': 'type parameter',
  \ }
