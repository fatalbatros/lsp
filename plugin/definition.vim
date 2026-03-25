vim9script

import "./sync.vim" as sync
import "./utils.vim" as utils

export def Definition()
    sync.ForceSync()
    const cursor = getpos('.')

    var uri = utils.GetCurrentUri()
    var request = {
        'method': 'textDocument/definition',
        'params': {
            'textDocument': {'uri': uri},
            'position': {
                'line': cursor[1] - 1,
                'character': cursor[2] - 1,
            }
        }
    }

    # TODO: ch_eval espera la respuesta, se puede poner un timeout
    var response = ch_evalexpr(g:lsp[&filetype]['channel'], request, {})
    g:lps_definition_response = response
    const result_raw = get(response, 'result', v:null)
    if result_raw == v:null || empty(result_raw)
        echo "LSP: No response for Definition"
        return
    endif

    var result = {}

    # The response can be Location | Location[] | LocationLink[]
    if type(result_raw) == type([])
        result = result_raw[0]
    else
        result = result_raw
    endif

    uri = ''
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

    execute(':edit ' .. utils.UriToPath(uri))
    cursor(line, character) 
enddef
