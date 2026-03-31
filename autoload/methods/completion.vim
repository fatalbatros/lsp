vim9script 

import autoload "sync.vim" as sync
import autoload "utils.vim" as utils

var last_cursor_context = {}
var last_completion_request = {}
var completion_list = []

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
    const cursor_context = GetCursorContext() 

    const line = cursor_context['line']
    const character = cursor_context['startcol']
    const uri = utils.GetCurrentUri()
    const params = {
        'textDocument': {'uri': uri},
        'position': {
            'line': line - 1,
            'character': character - 1,
        },
        'context': { 'triggerKind': 1},
    }

    const last_params = get(last_completion_request, 'params', {})

    if last_params == params && !empty(completion_list)
        timer_start(0, (_) => ShowCompletePopup(cursor_context['startcol'], cursor_context['base']))
        return
    endif

    var request = {
        'method': 'textDocument/completion',
        'params': params,
    }
    const status = ch_sendexpr(g:lsp[&filetype]['channel'], request, {'callback': 'OnComplete'})
    last_cursor_context = cursor_context
    last_completion_request = {'id': status.id, 'params': params }
    g:lsp_request = request
enddef


def OnComplete(channel: channel, response: dict<any>)
    g:lsp_response = response
    if response.id != last_completion_request.id | return | endif

    const result = get(response, 'result', v:null)
    if result == v:null
        echom 'LSP: Completion null response'
        return
    endif

    var data_list = [] 
    if type(result) == type({})     | data_list = result['items']
    elseif type(result) == type([]) | data_list = result
    else 
        echom 'LSP: Completion response no parseable' 
        return
    endif

    const base = last_cursor_context['base']
    const startcol = last_cursor_context['startcol']

    var list = []
    for i in data_list
        var label = trim(i['label'])
        var kind = get(i, 'kind', 0)
        var kind_text = get(completion__kinds, kind, '')

        var item = {
            'word': label,
            'abbr': label,
            'menu': kind_text,
            'user_data': {'score': 0 }
        }
        call add(list, item)
    endfor

    completion_list = list

    ShowCompletePopup(startcol, base)
enddef

def ShowCompletePopup(startcol: number, base: string)
    ComputeScore(completion_list, base)
    complete(startcol, sort(completion_list, ByScore))
enddef

def ComputeScore(list: list<dict<any>>, base: string)
    for item in list 
        item.user_data.score = item.word =~? '^' .. base ? 0 : 1
    endfor
enddef

#This Sort is to get the best match first
def ByScore(a: dict<any>, b: dict<any>): number
    if a.user_data.score != b.user_data.score
        return a.user_data.score - b.user_data.score
    endif
    return a.abbr < b.abbr ? -1 : (a.abbr > b.abbr ? 1 : 0)
enddef

const completion__kinds = {
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
