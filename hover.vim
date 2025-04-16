vim9script

import "./sync.vim" as sync

export def Hover()
  sync.ForceSync()
  const hover = {
     'method': 'textDocument/hover',
     'params': {
     'textDocument': {'uri': 'file://' .. expand("%:p") },
     'position': {'line': getpos('.')[1] - 1,
        'character': getpos('.')[2],
      }
     }
   }
  call ch_sendexpr(g:lsp[&filetype]['channel'], hover, {'callback': 'HoverCallback'})
enddef

def HoverCallback(channel: channel, response: dict<any>)
  echom response
  #let g:response = a:response
  if response['result'] == v:null | echo 'null response' | return | endif
  const hover_text = response['result']['contents']['value']
  const options = {
    'border': [1, 1, 1, 1],
    'highlight': 'Normal',
    'borderhighlight': ['LineNr'],
     borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'], 
    'moved': 'word',
  }
  const formated_text =  split(hover_text, '\r\n\|\r\|\n', v:true)
#   popup_atcursor(formated_text, options)
  popup_create(formated_text, options)
enddef

