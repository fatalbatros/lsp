vim9script 

import "./sync.vim" as sync


export def OmniLsp(findstart: number, base: string ): number
  if findstart
    return col('.')
  else
    Completion()
    return -2
  endif
enddef

def Completion()
  g:show_diagnostic = v:false
  au completedone <buffer> ++once g:show_diagnostic = v:true
  sync.ForceSync()
  var request = {
      'method': 'textDocument/completion',
      'params': {
         'textDocument': {'uri': 'file://' .. expand("%:p")},
         'position': {'line': getpos('.')[1] - 1, 'character': getpos('.')[2] - 1},
         'context': { 'triggerKind': 1 },
       },
   }
  ch_sendexpr(g:lsp[&filetype]['channel'], request, {'callback': 'OnComplete'})
enddef

def OnComplete(channel: channel, data: dict<any>)
  g:completion = data
  var data_list = []
  if type(data['result']) == type({})
    data_list = data['result']['items']
  else
    data_list = data['result']
  endif
  var list = []
  var left = strpart(getline('.'), 0, col('.') - 1)
  var last_word =  matchstr(left, '\(\k*$\)')
  for i in data_list
    var label = trim(i['label'])

    # TODO: si se saca el ^ de aca, puede hacer una especie de fuzzycomplete
    var word =  matchstr(label, '^' ..  last_word .. '\zs.*')
    var item = {
          'word': word,
          'abbr': label,
          'menu': completion__kinds[i['kind']],
          'info': 'Work In Progress',
          }
    call add(list, item)
  endfor
  list = sort(list, 'ByName')

  complete(col('.'), list)
enddef

def ByName(item1: dict<any>, item2: dict<any>): number
  var label1 = item1['abbr']
  var label2 = item2['abbr']
  if label1 == label2 | return 0 | endif
  var sorted = sort([label1, label2])
  if label1 == sorted[0] | return -1 | endif
  return 1
enddef


# augroup Completion
#   au!
#   au! CompleteChanged * call ShowExtraInfo()
# augroup END

def ShowExtraInfo()
  var info = complete_info()
  if info['mode'] != 'eval' | return | endif
  if info['selected'] == -1 | return | endif
  sync.ForceSync()
  var hover = {
     'method': 'textDocument/hover',
     'params': {
     'textDocument': {'uri': 'file://' .. expand("%:p")},
     'position': {'line': getpos('.')[1] - 1,
        'character': getpos('.')[2] - 1,
      }
    }
  }

  var response = ch_evalexpr(g:lsp[&filetype]['channel'], hover)
  if response['result'] == v:null | echo 'null response' | return | endif
  var hover_text = response['result']['contents']['value']
  var formated_text =  split(hover_text, '\r\n\|\r\|\n', v:true)
  var id = popup_findinfo()
  if id != 0
    popup_settext(id, formated_text)
    popup_show(id)
  endif
enddef


var completion__kinds = {
  '1': 'text',
  '2': 'method',
  '3': 'function',
  '4': 'constructor',
  '5': 'field',
  '6': 'variable',
  '7': 'class',
  '8': 'interface',
  '9': 'module',
  '10': 'property',
  '11': 'unit',
  '12': 'value',
  '13': 'enum',
  '14': 'keyword',
  '15': 'snippet',
  '16': 'color',
  '17': 'file',
  '18': 'reference',
  '19': 'folder',
  '20': 'enum member',
  '21': 'constant',
  '22': 'struct',
  '23': 'event',
  '24': 'operator',
  '25': 'type parameter',
}
