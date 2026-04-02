vim9script 

import autoload "workspace/edit.vim" as edit_actions

import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils
import autoload "lsp/request.vim" as Request
import autoload "methods/actions/utils.vim" as ActionsUtils


export def OrganizeImports()
    sync.ForceSync()

    const cursor = getpos('.')
    const uri = utils.GetCurrentUri()
    var request = {
        'method': 'textDocument/codeAction',
        'params': {
            'textDocument': {'uri': uri},
            'range': {
                'start': { 'line': cursor[1] - 1, 'character': cursor[2] - 1, },
                'end': { 'line': cursor[1] - 1, 'character': cursor[2] - 1, },
            },
            'context': {
                'diagnostics': [],
                'triggerKind': 1,
                'only': ['source.organizeImports'],
            }
        }
    }
    g:lsp_request = request

    Request.Send(&filetype, request, {'callback': (ch, res) => OrganizeImportsCB(ch, res) })
enddef

def OrganizeImportsCB(channel: channel, response: dict<any>)
    g:lsp_response = response
    const result = get(response, 'result', v:null)
    if result == v:null | return | endif
    const normalized = ActionsUtils.NormalizeCodeActionResult(result)

    var actions = []
    for action in normalized 
        if index(actions, action) != -1 | continue | endif
        add(actions, action)
    endfor
    
    if empty(actions) | return | endif
    for action in actions
        var changes = action.changes
        edit_actions.ApplyChanges(changes)
    endfor
enddef
