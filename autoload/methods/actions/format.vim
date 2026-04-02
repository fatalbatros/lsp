vim9script 

import autoload "workspace/edit.vim" as Edit
import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils
import autoload "lsp/request.vim" as Request


export def Format()
    sync.ForceSync()
    var spaces  = input('Spaces[^\d$] for tab: ')
    if spaces !~ '^\d$' | redraw! | return | endif

    const uri = utils.GetCurrentUri()
    var request = {
        'method': 'textDocument/formatting',
        'params': {
            'textDocument': {'uri': uri},
            'options': {
                'tabSize': str2nr(spaces),
                'insertSpaces': v:true,
                'trimTrailingWhitespace': v:true,
                'insertFinalNewline': v:true,
                'trimFinalNewlines': v:true,
            }
        }
    }
    g:lsp_request = request

    Request.Send(&filetype, request, {'callback': (ch, res) => FormatCB(ch, res, uri) })
enddef

def FormatCB(channel: channel, response: dict<any>, uri: string)
    g:lsp_response = response
    const result = get(response, 'result', v:null)
    if result == v:null | return | endif

    Edit.ApplyArrayTextEdit(uri, result)
enddef
