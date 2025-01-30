function Completion() abort
  call ForceSync()
  let l:request = {
      \'method': 'textDocument/completion',
      \'params': {
      \   'textDocument': {'uri': 'file://' . expand("%:p")},
      \   'position': {'line': getpos('.')[1]-1,'character': getpos('.')[2]-1},
      \   'context': { 'triggerKind': 1 },
      \ },
  \ }
  echom l:request
  call ch_sendexpr(g:lsp[&filetype]['channel'], l:request, {'callback':'s:OnComplete'})
  "ch_evalexpr waits for the response. A timeout can be set in opt
  "let g:comple = ch_evalexpr(g:lsp[&filetype]['channel'], l:request, {})
  "There is a field isComplete that I am ignoring, I thinks it is for the case
  "that the callback is not complete.
"  return g:comple['result']['items']
endfunction 

function! s:OnComplete(channel, data) abort
  let g:completion = a:data
  if type(a:data['result']) == type({})
     let l:data = a:data['result']['items']
  else
     let l:data = a:data['result']
  endif
  let l:list = []
  let l:left = strpart(getline('.'), 0, col('.')-1)
  let l:last_word = matchstr(l:left, '\(\k*$\)')
  for i in l:data
    let l:label = trim(i['label'])

    "TODO: si se saca el ^ de aca, puede hacer una especie de fuzzycomplete"
    let l:word = matchstr(l:label, '^' ..  l:last_word .. '\zs.*')
"    echom 'match: ' .. l:word
    let l:item = {
          \'word': l:word,
          \'abbr': l:label,
          \'menu': s:completion__kinds[i['kind']],
          \'info': 'Work In Progress',
          \}
    "TODO: hay que sortear la lista
    call add(l:list, l:item )
  endfor

"  echom l:list
  call complete(col('.'), l:list)
endfunction


set <A-z>=z
imap <A-z> :call Completion()<CR>
set completeopt=menu,menuone,popuphidden
set omnifunc=OmniLsp

augroup Completion
  au!
  au! CompleteChanged * call s:ShowExtraInfo()
augroup END

function! OmniLsp(findstart, base ) abort
  if a:findstart
    return col('.')
  else
  call Completion()
  return -2
endfunction


function s:ShowExtraInfo() abort
  let l:info = complete_info()
  if l:info['mode'] != 'eval' | return | endif
  if l:info['selected'] == -1 | return | endif
  call ForceSync()
  let l:hover = {
    \ 'method':'textDocument/hover',
    \ 'params': {
    \ 'textDocument': {'uri': 'file://' . expand("%:p")},
    \ 'position': {'line': getpos('.')[1]-1,
        \ 'character': getpos('.')[2]-1,
      \}
    \ }
  \ }
  echom l:hover
  let response = ch_evalexpr(g:lsp[&filetype]['channel'], l:hover)
  if l:response['result'] == v:null | echo 'null response' | return | endif
  let l:hover_text = l:response['result']['contents']['value']
  let l:formated_text =  split(l:hover_text, '\r\n\|\r\|\n', v:true)
  let l:id = popup_findinfo()
  if l:id
    call popup_settext(id, l:formated_text)
  " call popup_setoptions(id,{} )
    call popup_show(id)
  endif
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
