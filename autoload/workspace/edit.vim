vim9script 

import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils

export def ApplyEdit(edit: dict<any>) 
    var changes = edit.changes
    for [uri, list]  in items(changes)
        SingleEdit(uri, list)
        sync.ForceSyncUri(uri)
    endfor
enddef


def SingleEdit(uri: string, list: list<dict<any>>)
    const bufnr = utils.EnsureBuffer(uri)

    var sorted = sort(list, (a, b) => {
        if a.range.start.line != b.range.start.line
            return b.range.start.line - a.range.start.line
        endif
        return b.range.start.character - a.range.start.character
    })

    for i in sorted 
        const start = i.range.start
        const end = i.range.end
        const newText = i.newText
        const newLines = split(newText, '\n', 1)

        const line = getbufline(bufnr, start.line + 1)[0]
        const text_before = strpart(line, 0, start.character)
        const text_after = strpart(line, end.character)

        if len(newLines) == 1
            setbufline(bufnr, start.line + 1, text_before .. newLines[0] .. text_after)
        else
            setbufline(bufnr, start.line + 1, text_before .. newLines[0])
            appendbufline(bufnr, start.line + 1, newLines[1 :])
            const last_line = start.line + len(newLines)
            setbufline(bufnr, last_line, getbufline(bufnr, last_line)[0] .. text_after)
        endif
    endfor
enddef


