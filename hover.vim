function Hover() abort
  call ForceSync()
  let l:hover = {
    \ 'method':'textDocument/hover',
    \ 'params': {
    \ 'textDocument': {'uri': 'file://' . expand("%:p")},
    \ 'position': {'line': getpos('.')[1]-1,
        \ 'character': getpos('.')[2],
      \}
    \ }
  \ }
  call ch_sendexpr(g:lsp[&filetype]['channel'],l:hover,{'callback':'s:HoverCallback'})
endfunction 

function! s:HoverCallback(channel,response) abort
  echom 'HoverCallback'
  echom a:response
  let g:response = a:response
  if a:response['result'] == v:null | echo 'null response' | return | endif
  let l:hover_text = a:response['result']['contents']['value']
  let l:options = {
    \'border':[1,1,1,1],
    \'highlight':'Normal',
    \'borderhighlight': ['LineNr'],
    \'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└'], 
    \'moved':'word'
  \}
"    'borderchars':['-','|','-','|','+','+','+','+'],
  let l:formated_text =  split(l:hover_text, '\r\n\|\r\|\n', v:true)
  call popup_atcursor(l:formated_text,l:options)
endfunction

"nnoremap K :call Hover()<CR>
