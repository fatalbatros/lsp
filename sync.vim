
def g:DidClose(file: string)
  var uri = 'file://' .. file
  var filetype: string 
  var didClose = {
    'method': 'textDocument/didClose',
    'params': {
      'textDocument': {
        'uri': uri,
      },
    },
  }

  for ft in keys(g:lsp)
    if !has_key(g:lsp[ft], 'files') | continue | endif
    if has_key(g:lsp[ft]['files'], uri)
      filetype = ft
    endif
  endfor

  ch_sendexpr(g:lsp[filetype]['channel'], didClose)
  unlet g:lsp[filetype]['files'][uri]
  if exists("g:diagnostics")
    if has_key(g:diagnostics, uri)
      unlet g:diagnostics[uri] 
    endif
  endif
enddef


def s:get_lines():  string
  var lines = getbufline(bufnr(), 1, '$')
  return join(lines, "\n")
enddef

def s:DidOpen(uri: string)
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


def s:DidChange(uri: string, version: number)
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


def g:ForceSync()
  var uri = 'file://' .. expand("%:p")
  if !has_key(g:lsp[&filetype]['files'], uri)
    g:lsp[&filetype]['files'][uri] = {'bufer': bufnr(), 'version': 1}
    b:sync_changedtick = b:changedtick
    s:DidOpen(uri)
  else
    if b:sync_changedtick != b:changedtick
      var new_version = g:lsp[&filetype]['files'][uri]['version'] + 1
      g:lsp[&filetype]['files'][uri]['version'] = new_version
      b:sync_changedtick = b:changedtick
      s:DidChange(uri, new_version)
    endif
  endif
enddef
