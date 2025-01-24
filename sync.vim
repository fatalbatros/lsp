function! ForceSync() abort
  let l:uri = 'file://' . expand("%:p")
  if !has_key(g:lsp[&filetype]['files'], l:uri)
    let g:lsp[&filetype]['files'][l:uri] = {'bufer': bufnr(), 'version': 1}
    let b:sync_changedtick = b:changedtick
    call DidOpen(l:uri)
  else
    if b:sync_changedtick != b:changedtick
      let l:new_version = g:lsp[&filetype]['files'][l:uri]['version'] + 1
      let g:lsp[&filetype]['files'][l:uri]['version'] = l:new_version
      let b:sync_changedtick = b:changedtick
      call DidChange(l:uri, l:new_version)
    endif
  endif
endfunction

function! DidClose(file) abort
  let l:uri = 'file://' . a:file
  let l:didClose = {
    \'method':'textDocument/didClose',
    \'params':{
      \'textDocument': {
        \'uri': l:uri,
      \},
    \},
  \}
  call ch_sendexpr(g:lsp[&filetype]['channel'], l:didClose)
  unlet g:lsp[&filetype]['files'][l:uri]
  if exists("g:diagnostics")
    if has_key(g:diagnostics, l:uri) | unlet g:diagnostics[l:uri] | endif
  endif
endfunction


def s:get_lines():  string
  var lines = getbufline(bufnr(), 1, '$')
  return join(lines, "\n")
enddef

def DidOpen(uri: string)
  var didOpen = {
    'method': 'textDocument/didOpen',
    'params': {
      'textDocument': {
        'uri': uri,
        'languageId': &filetype, 
        'version': 1,
        'text': s:get_lines(),
      },
    },
  }
  call ch_sendexpr(g:lsp[&filetype]['channel'], didOpen)
enddef


def g:DidChange(uri: string, version: number)
  var didChange = {
    'method': 'textDocument/didChange',
    'params': {
      'textDocument': {
        'uri': uri,
        'languageId': &filetype, 
        'version':  version,
      },
      'contentChanges': [{'text': s:get_lines() }],
    },
  }
  call ch_sendexpr(g:lsp[&filetype]['channel'], didChange)
enddef
