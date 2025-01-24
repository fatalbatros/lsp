function Completion() abort
  call SyncFile()
  let l:request = {
      \'method': 'textDocument/completion',
      \'params': {
      \   'textDocument': {'uri': 'file://' . expand("%:p")},
      \   'position': {'line': getpos('.')[1]-1,'character': getpos('.')[2]},
      \   'context': { 'triggerKind': 1 },
      \ },
  \ }
  call ch_sendexpr(g:lsp[&filetype]['channel'],l:request,{'callback':'s:CompletionCallback'})
endfunction 

function! s:CompletionCallback(channel,response) abort
  echom 'CompletionCallback'
  echom a:response
  let g:response = a:response
endfunction
