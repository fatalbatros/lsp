
function! ForceSync() abort
  let l:uri = 'file://' . expand("%:p")
  if !has_key(g:lsp[&filetype]['files'], l:uri)
    let b:sync_changedtick = b:changedtick
    call s:DidOpen(l:uri)
  else
    if b:sync_changedtick != b:changedtick
      let b:sync_changedtick = b:changedtick
      call s:DidChange(l:uri)
    endif
  endif
endfunction

function! s:DidOpen(uri) abort
  let l:didOpen = {
    \'method':'textDocument/didOpen',
    \'params':{
      \'textDocument': {
        \'uri': a:uri,
        \'languageId': &filetype, 
        \'version': 1,
        \'text': s:get_lines(),
      \},
    \},
  \}
  call ch_sendexpr(g:lsp[&filetype]['channel'],l:didOpen)
  let g:lsp[&filetype]['files'][a:uri] = {'bufer': bufnr(), 'version': 1}
endfunction


function! DidClose(file) abort
  let l:uri = 'file://' .. a:file
  let l:didClose = {
    \'method':'textDocument/didClose',
    \'params':{
      \'textDocument': {
        \'uri': l:uri,
      \},
    \},
  \}

  for ft in keys(g:lsp)
    if !has_key(g:lsp[ft], 'files') | continue | endif
    if has_key(g:lsp[ft]['files'], l:uri)
      let l:filetype = ft
    endif
  endfor

  call ch_sendexpr(g:lsp[l:filetype]['channel'], l:didClose)
  unlet g:lsp[l:filetype]['files'][l:uri]
    if has_key(g:diagnostics, l:uri)
      unlet g:diagnostics[l:uri]
    endif
endfunction

function! s:get_lines() abort
  let l:lines = getbufline(bufnr(), 1, '$')
  return join(l:lines, "\n")
endfunction

function! s:DidChange(uri) abort
  let l:version = g:lsp[&filetype]['files'][a:uri]['version']
  let g:lsp[&filetype]['files'][a:uri]['version'] += 1
  let l:didChange = {
    \'method':'textDocument/didChange',
    \'params':{
      \'textDocument': {
        \'uri': a:uri,
        \'languageId': &filetype, 
        \'version': l:version + 1,
      \},
      \'contentChanges': [{'text': s:get_lines() }],
    \},
  \}
  call ch_sendexpr(g:lsp[&filetype]['channel'],l:didChange)
endfunction
