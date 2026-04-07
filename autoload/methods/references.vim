vim9script

import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils
import autoload "lsp/request.vim" as Request


export def References()
    sync.ForceSync()
    const cursor = getpos('.')

    var uri = utils.GetCurrentUri()
    var request = {
        'method': 'textDocument/references',
        'params': {
            'textDocument': {'uri': uri},
            'position': {
                'line': cursor[1] - 1,
                'character': cursor[2] - 1,
            },
            'context': {
                'includeDeclaration': v:false
            },
        },
    }
    g:lsp_request = request

    Request.Send(&filetype, request, {'callback': (ch, res) => ReferencesCB(ch, res) })
enddef

def ReferencesCB(channel: channel, response: dict<any>)
    g:lsp_response = response
    const result = get(response, 'result', v:null)
    if result == v:null | return | endif
    
    var list = []
    for item in result
        var filename = fnameescape(utils.UriToPath(item.uri))
        var line = item.range.start.line + 1
        var col = item.range.start.character + 1
        add(list, {'filename': filename, 'lnum': line, 'col': col})
    endfor

    setqflist(list)
    cwindow
enddef
