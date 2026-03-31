vim9script 

import autoload "sync.vim" as sync
import autoload "utils.vim" as utils
import autoload "lsp/request.vim" as Request
import autoload "workspace/edit.vim" as edit


export def Rename()
    sync.ForceSync()
    const cursor = getpos('.')
    const oldName = expand('<cword>')
    const newName = input('Rename ' .. oldName .. ' to: ')
    if empty(newName) | redraw! | return | endif

    var uri = utils.GetCurrentUri()
    var request = {
        'method': 'textDocument/rename',
        'params': {
            'textDocument': {'uri': uri},
            'position': { 'line': cursor[1] - 1, 'character': cursor[2] - 1, },
            'newName': newName
        }
    }
    g:lsp_request = request

    Request.Send(&filetype, request, {'callback': (ch, res) => RenameCallback(ch, res) })
enddef

def RenameCallback(channel: channel, response: dict<any>)
    g:lsp_response = response

    const result = get(response, 'result', v:null)
    if result == v:null | return | endif
    ShowRenamePopup(result)    
enddef

def Filter(id: number, key: string, result: dict<any>): bool
    if key == "\<CR>"
        edit.ApplyEdit(result)
        popup_close(id)
    else
        popup_close(id)
    endif

    redraw!
    return true
enddef

def ShowRenamePopup(result: dict<any>)
    var changes = get(result, 'changes', v:null)
    if changes == v:null | return | endif

    var by_folder = {}
    for [uri, list] in items(changes)
        var fname = utils.UriToPath(uri)
        var folder = fnamemodify(fname, ":~:.:h")
        var name = fnamemodify(fname, ":t")

        if !has_key(by_folder, folder) 
            by_folder[folder] = []
        endif
        add(by_folder[folder], [len(list), name])
    endfor

    var lines = []

    var folders = keys(by_folder)
    sort(folders)

    for folder in folders
        var files = by_folder[folder]
        sort(files, (a, b) => b[0] - a[0])
        add(lines, folder .. "/")
        for file in files
            add(lines, printf('%3d edits     %s  ', file[0], file[1]) )
        endfor

        add(lines, "")
    endfor

    if empty(lines) | return | endif

    const options = {
        border: [1, 1, 1, 1],
        highlight: 'Normal',
        borderhighlight: ['LineNr'],
        borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'], 
        filter: (id, key) => Filter(id, key, result),
    }

    popup_create(lines, options)
enddef
