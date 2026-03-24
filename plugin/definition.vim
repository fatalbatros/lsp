vim9script

import "./sync.vim" as sync

export def Definition()
    sync.ForceSync()
    const cursor = getpos('.')
    var request = {
        'method': 'textDocument/definition',
        'params': {
            'textDocument': {'uri': 'file://' .. expand("%:p")},
            'position': {
                'line': cursor[1] - 1,
                'character': cursor[2] - 1,
            }
        }
    }

    # TODO: ch_eval espera la respuesta, se puede poner un timeout
    var response = ch_evalexpr(g:lsp[&filetype]['channel'], request, {})
    if !has_key(response, 'result') || empty(response['result'])
        echo "No response from LSP"
        return
    endif
    var result = {}

    # The response can be Location | Location[] | LocantionLink[]
    if type(response['result']) == type([])
        result = response['result'][0]
    else
        result = response['result']
    endif

    var uri = ''
    var pos = {}
    if has_key(result, 'targetUri')
        uri = result['targetUri']
        pos = result['targetSelectionRange']['start']
    else
        uri = result['uri']
        pos = result['range']['start']
    endif

    const line = pos['line'] + 1
    const character = pos['character'] + 1

    execute(':edit ' .. fnameescape(Parse_uri(uri)))
    setcursorcharpos(line, character) 
enddef

def Parse_uri(uri: string): string
    return substitute(uri, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
enddef
