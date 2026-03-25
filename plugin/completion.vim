vim9script 

import "./sync.vim" as sync
import "./utils.vim" as utils

var last_cursor_context = {}

export def OmniLsp(findstart: number, base: string ): number
    if findstart
        return col('.')
    else
        Completion()
        return -2
    endif
enddef

def GetCursorContext(): dict<any>
    # this starcol is to handle the case where lps returns null when calling
    # completions in `self._|` this make call to complete from `self.|_`
    # ignoring what is after `self.`. This could seems an overkill but lps
    # returns every completion posible for `self.` even when calling it in
    # `self.func`
    const cursor = getpos('.')
    const col = cursor[2]
    const line = cursor[1]
    const line_text = getline('.')
    const left = strpart(line_text, 0, col - 1)
    const base = matchstr(left, '\k*$')

    return {
        'col': col,
        'line': line,
        'base': base,
        'startcol': col - len(base),
    }
enddef

def Completion()
    sync.ForceSync()
    const cursor = getpos('.')
    last_cursor_context = GetCursorContext() 

    const line = last_cursor_context['line'] - 1
    const character = last_cursor_context['startcol'] - 1
    const uri = utils.GetCurrentUri()

    var request = {
        'method': 'textDocument/completion',
        'params': {
            'textDocument': {'uri': uri},
            'position': {
                'line': line,
                'character': character,
            },
            'context': { 'triggerKind': 1},
        },
    }
    ch_sendexpr(g:lsp[&filetype]['channel'], request, {'callback': 'OnComplete'})
enddef

def OnComplete(channel: channel, data: dict<any>)
    g:lsp_completion = data

    const result = get(data, 'result', v:null)
    if result == v:null
        echom 'LSP: Completion null response'
        return
    endif

    var data_list = []
    if type(data['result']) == type({})
        data_list = data['result']['items']
    elseif type(data['result']) == type([])
        data_list = data['result']
    else 
        echom 'LSP: Completion response no parseable' 
        return
    endif

    var base = last_cursor_context['base']
    var startcol = last_cursor_context['startcol']

    var list = []
    for i in data_list
        var label = trim(i['label'])
        var kind = get(i, 'kind', 0)
        var kind_text = get(completion__kinds, kind, '')
        var score = label =~? '^' .. base ? 0 : 1

        var item = {
            'word': label,
            'abbr': label,
            'menu': kind_text,
            'user_data': {'score': score }
        }
        call add(list, item)
    endfor

    list = sort(list, ByScore)
    g:lsp_completion_list = list
    complete(startcol, list)
enddef

#This Sort is to get the best match first
def ByScore(a: dict<any>, b: dict<any>): number
    if a.user_data.score != b.user_data.score
        return a.user_data.score - b.user_data.score
    endif
    return a.abbr < b.abbr ? -1 : (a.abbr > b.abbr ? 1 : 0)
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
