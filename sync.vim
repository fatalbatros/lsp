vim9script

export def DidClose(file: string)
  var uri = 'file://' .. file
  var didClose = {
    'method': 'textDocument/didClose',
    'params': {
      'textDocument': {
        'uri': uri,
      },
    },
  }
  
  var filetype = g:synchronized[uri]['filetype']
  ch_sendexpr(g:lsp[filetype]['channel'], didClose)
  unlet g:synchronized[uri]
  if has_key(g:diagnostics, uri)
    unlet g:diagnostics[uri] 
  endif
enddef


def Get_lines():  string
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
        'text': Get_lines(),
      },
    },
  }
  call ch_sendexpr(g:lsp[&filetype]['channel'], didOpen)
enddef


def DidChange(uri: string, version: number)
  var didChange = {
    'method': 'textDocument/didChange',
    'params': {
      'textDocument': {
        'uri': uri,
        'languageId': &filetype, 
        'version':  version,
      },
      'contentChanges': [{'text': Get_lines() }],
    },
  }
  call ch_sendexpr(g:lsp[&filetype]['channel'], didChange)
enddef


export def ForceSync()
  var uri = 'file://' .. expand("%:p")
  if !has_key(g:synchronized, uri)
    g:synchronized[uri] = {'bufer': bufnr(), 'version': 1, 'filetype': &filetype}
    b:sync_changedtick = b:changedtick
    DidOpen(uri)
  else
    if b:sync_changedtick != b:changedtick
      var new_version = g:synchronized[uri]['version'] + 1
      g:synchronized[uri]['version'] = new_version
      b:sync_changedtick = b:changedtick
      DidChange(uri, new_version)
    endif
  endif
enddef
