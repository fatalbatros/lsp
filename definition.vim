function Definition() abort
  call SyncFile()
  let l:hover = {
    \ 'method':'textDocument/definition',
    \ 'params': {
    \ 'textDocument': {'uri': 'file://' . expand("%:p")},
    \ 'position': {'line': getpos('.')[1]-1,
        \ 'character': getpos('.')[2],
      \}
    \ }
  \ }
  call ch_sendexpr(g:lsp[&filetype]['channel'],l:hover,{'callback':'s:DefinitionCallBack'})
endfunction 

function! s:DefinitionCallBack(channel,response) abort
  echom 'DefinitionCallBack'
  echom a:response
  let g:response = a:response
  if a:response['result'] == v:null | echo 'null response' | return | endif
  "the result is a list and can have various files. I dont know why.
  "write something to handle multiple definitions, maybe use a qf list.
  let l:uri = a:response['result'][0]['uri']
  "there might be a problem with position. I think that a tab counts as a
  "single character that span several colums. Research this.
  let l:line = a:response['result'][0]['range']['start']['line'] + 1
  let l:character = a:response['result'][0]['range']['start']['character'] + 1
  execute(':edit '.expand(l:uri))
  call setcursorcharpos(l:line,l:character) 
endfunction

