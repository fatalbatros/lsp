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
    # NOTE: I dont remember why I added this, check if something break
#     g:show_diagnostic = v:false
#     au completedone <buffer> ++once g:show_diagnostic = v:true
    sync.ForceSync()
    const cursor = getpos('.')

    # this is to handle the case where lps returns null when calling
    # completions in `self._|` this make call to complete from `self.|_`
    # ignoring what is after `self.`. This could seems an overkill but lps
    # returns every completion posible for `self.` even when calling it in
    # `self.func`
    const col = cursor[2] - 1
    var line = getline('.')
    var left = strpart(line, 0, col)
    var base = matchstr(left, '\k*$')
    var adjusted_col = col - len(base)

    var request = {
        'method': 'textDocument/completion',
        'params': {
            'textDocument': {'uri': 'file://' .. expand("%:p")},
            'position': {
                'line': cursor[1] - 1,
                'character': adjusted_col,
#                 'character': cursor[2] -1,
            },
            'context': { 'triggerKind': 1},
        },
    }
    ch_sendexpr(g:lsp[&filetype]['channel'], request, {'callback': 'OnComplete'})
enddef

def OnComplete(channel: channel, data: dict<any>)
    g:completion = data
    if !has_key(data, 'result') || data['result'] == v:null
        echom 'g:completion parse error'
        return
    endif

    var data_list = []
    if type(data['result']) == type({})
        data_list = data['result']['items']
    elseif type(data['result']) == type([])
        data_list = data['result']
    else 
        echom 'g:completion parse error' 
        return
    endif

    var left = strpart(getline('.'), 0, col('.') - 1)
    var last_word =  matchstr(left, '\(\k*$\)')

    var list = []
    for i in data_list
        var label = trim(i['label'])
        var kind = get(i, 'kind', 0)
        var kind_text = get(completion__kinds, kind, '')
        var item = {
              'word': label,
              'abbr': label,
              'menu': kind_text,
              }
        call add(list, item)
    endfor

    var Sorter = (a, b) => ByScore(a, b, last_word)

    list = sort(list, Sorter)
    complete(col('.') - len(last_word), list)
enddef

#This Sort is to get the best match first
def ByScore(item1: dict<any>, item2: dict<any>, base: string): number
    var l1 = item1['abbr']
    var l2 = item2['abbr']

    var s1 = l1 =~? '^' .. base ? 0 : 1
    var s2 = l2 =~? '^' .. base ? 0 : 1

    if s1 != s2
        return s1 - s2
    endif

    return l1 < l2 ? -1 : (l1 > l2 ? 1 : 0)
enddef

# augroup Completion
#   au!
#   au! CompleteChanged * call ShowExtraInfo()
# augroup END


# TODO: Complete this.
# Do not use hover, use details/documentation. The lsp also sends data on
# completion requiest, cache that and use it. it is free.
export def ShowExtraInfo()
    const info = complete_info(['selected', 'items'])
    if info['selected'] == -1 | return | endif
    const cursor = getpos('.')
    const hover = {
        'method': 'textDocument/hover',
        'params': {
            'textDocument': {'uri': 'file://' .. expand("%:p")},
            'position': {'line': cursor[1] - 1,
                'character': cursor[2] - 1,
            }
        }
    }

    const response = ch_evalexpr(g:lsp[&filetype]['channel'], hover)
    g:lsp_extra = response
    if response['result'] == v:null | echo 'null response' | return | endif
    const hover_text = response['result']['contents']['value']
    const formated_text =  split(hover_text, '\r\n\|\r\|\n', v:true)
    const id = popup_findinfo()

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
