vim9script 

import autoload "workspace/edit.vim" as Edit

import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils
import autoload "lsp/request.vim" as Request
import autoload "methods/actions/utils.vim" as ActionsUtils
import autoload "diagnostic.vim" as diag


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
        Edit.ApplyChanges(changes)
        diag.ParseDiagnostics()
    endfor
enddef


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
    diag.ParseDiagnostics()
enddef

export def Fmt()
    var lines = [
        "Organize Imports",
        "Change tabsize"
    ]
    var options = {
        border: [1, 1, 1, 1],
        highlight: 'Normal',
        borderhighlight: ['LineNr'],
        borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'], 
        filter: FilterFmt,
    }

    popup_menu(lines, options)
enddef

def FilterFmt(id: number, key: string): bool
    if key == "\<CR>"
        const line_nr = line('.', id)
        if line_nr == 1
            OrganizeImports() 
        elseif line_nr == 2
            Format()
        endif
        popup_close(id, 0)
    else
        return popup_filter_menu(id, key)
    endif

    return true
enddef
