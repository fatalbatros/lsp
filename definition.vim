vim9script

import "./sync.vim"

def g:Definition()
  g:ForceSync()
  var request = {
    'method': 'textDocument/definition',
    'params': {
      'textDocument': {'uri': 'file://' .. expand("%:p")},
      'position': {'line': getpos('.')[1] - 1,
        'character': getpos('.')[2],
      }
     }
   }

  # TODO: ch_eval espera la respuesta, se puede poner un timeout
  var response = ch_evalexpr(g:lsp[&filetype]['channel'], request, {})
  if empty(response['result']) 
    echo "null response"
    return
  endif
  var result = {}
  if type(response['result']) == type([])
    result = response['result'][0]
  else
    result = response['result']
  endif

  var uri = result['uri']
  var line = result['range']['start']['line'] + 1
  var character = result['range']['start']['character'] + 1
  execute(':edit ' .. fnameescape(uri))
  setcursorcharpos(line, character) 
enddef
