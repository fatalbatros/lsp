vim9script 

import autoload "workspace/edit.vim" as edit_actions

import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils
import autoload "diagnostic.vim" as diag
import autoload "lsp/request.vim" as Request

var code_actions = []
var show_preview = v:false


if empty(prop_type_get('LspDiffVirtualAdd'))
    prop_type_add('LspDiffVirtualAdd', { highlight: 'Added', priority: -10 })
endif

if empty(prop_type_get('LspDiffVirtualDelete'))
    prop_type_add('LspDiffVirtualDelete', { highlight: 'MatchParen',   priority: -10})
endif

export def CodeActions()
    sync.ForceSync()
    const cursor = getpos('.')

    var uri = utils.GetCurrentUri()
    var request = {
        'method': 'textDocument/codeAction',
        'params': {
            'textDocument': {'uri': uri},
            'range': {
                'start': { 'line': cursor[1] - 1, 'character': cursor[2] - 1, },
                'end': { 'line': cursor[1] - 1, 'character': cursor[2] - 1, },
            },
            'context': {
                'diagnostics': b:diagnostics,
                'triggerKind': 1,
                'only': ['quickfix'],
#                'only': ['', 'quickfix', 'refactor', 'refactor.extract', 'refactor.inline', 'refactor.rewrite', 'source', 'source.organizeImports'],
            }
        }
    }
    g:lsp_request = request

    Request.Send(&filetype, request, {'callback': (ch, res) => CodeActionsCB(ch, res) })
enddef

def CodeActionsCB(channel: channel, response: dict<any>)
    g:lsp_response = response
    const result = get(response, 'result', v:null)
    if result == v:null | return | endif

    var list = []
    for action in result 
        if get(action, 'kind', '') !~# '^quickfix' | continue | endif
        var to_add = {'edit': action.edit, 'title': action.title, 'kind': action.kind }

        # this only works if the server sends two edits that are the same edit
        # in the same exact order of it keys.
        if index(list, to_add) != -1 | continue | endif
        add(list, to_add)
    endfor
    
    if empty(list) | return | endif
    code_actions = list
    ShowActions()
enddef

def ShowActions()
    var lines = []
    for i in range(len(code_actions))
        var action = code_actions[i]
        var title = action.title

        var text = printf('%s', title)
        add(lines, text)
    endfor

    var options = {
        border: [1, 1, 1, 1],
        highlight: 'Normal',
        borderhighlight: ['LineNr'],
        borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'], 
        filter: Filter,
        callback: (id, result) => {
            show_preview = v:false
            CleanPreview()
            diag.ParseDiagnostics()
        }
    }

    popup_menu(lines, options)
enddef
 
def Filter(id: number, key: string): bool
    var id_line = line('.', id) - 1
    var action = code_actions[id_line]

    if key == "\<CR>"
        edit_actions.ApplyEdit(action.edit)
        popup_close(id)
        return true
    endif

    if key == 'p'
        show_preview = v:true
        ShowPreview(action)
        return true
    endif

    if (key == 'j' || key == 'k' || key == "\<Down>" || key == "\<Up>")
        var handled = popup_filter_menu(id, key)
        id_line = line('.', id) - 1
        action = code_actions[id_line]
        ShowPreview(action)
        return handled
    endif

    popup_close(id)
    return false
enddef

def ShowPreview(action: dict<any>)
    if show_preview == v:false | return | endif

    CleanPreview()

    for [uri, edits] in items(action.edit.changes)

        for e in edits
            var lnum = e.range.start.line + 1
            var diff = ComputeSingleDiff(uri, e)
            var diff_line = split(diff, '\n')
            for l in diff_line
                if l[0] == '-'
                    prop_add(lnum, 0, {
                        type: 'LspDiffVirtualDelete',
                        text: l,
                        text_align: 'above'
                    })

                elseif l[0] == '+'
                    prop_add(lnum,  0, {
                        type: 'LspDiffVirtualAdd',
                        text: l,
                        text_align: 'above'
                    })
                endif
            endfor
        endfor
    endfor
enddef


def ComputeSingleDiff(uri: string, edit: dict<any>): string
    const bufnr = utils.EnsureBuffer(uri)

    var  start = edit.range.start
    var end = edit.range.end
    var start_l = start.line + 1
    var end_l = end.line + 1

    var oldLines = getbufline(bufnr, start_l, end_l)

    var first = oldLines[0]
    var last  = oldLines[-1]

    var before = strpart(first, 0, start.character)
    var after  = strpart(last, end.character)

    var newLines = split(edit.newText, '\n', 1)

    if len(newLines) == 1
        newLines = [before .. newLines[0] .. after]
    else
        newLines[0] = before .. newLines[0]
        newLines[-1] = newLines[-1] .. after
    endif

    return diff(oldLines, newLines)
enddef

def CleanPreview()
    prop_clear(1, line('$'), {'type': 'LspDiffVirtualAdd'})
    prop_clear(1, line('$'), {'type': 'LspDiffVirtualDelete'})
enddef 
