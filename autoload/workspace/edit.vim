vim9script 

import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils

export def ApplyEdit(edit: dict<any>) 
    # edit = WorkSpaceEdit  {
    #   changes?: {uri, textEdit[]},
    #   documentChanges?: TextDocumentEdit[] | (TextDocumentEdit | CreateFile | RenameFile | DeleteFile )[]
    # }
    g:edit = edit
    const changes = get(edit, 'changes', v:null)
    if changes != v:null
        for [uri, list]  in items(changes)
            SingleFileEdit(uri, list)
            sync.ForceSyncUri(uri)
        endfor
        return
    endif

    const documentChanges = get(edit, 'documentChanges', v:null)
    if documentChanges != v:null
        for  textDocumentEdit in documentChanges
            var uri = textDocumentEdit.textDocument.uri
            var list = textDocumentEdit.edits
            SingleFileEdit(uri, list)
            sync.ForceSyncUri(uri)
        endfor
        return
    endif
enddef


def SortEdits(a: dict<any>, b: dict<any>): number
    if a.range.start.line != b.range.start.line
        return b.range.start.line - a.range.start.line
    endif
    return b.range.start.character - a.range.start.character
enddef


def SingleFileEdit(uri: string, list: list<dict<any>>)
    const bufnr = utils.EnsureBuffer(uri)

    var sorted = sort(list, SortEdits)

    for i in sorted
        const start = i.range.start
        const end = i.range.end
        var newLines = split(i.newText, '\n', 1)

        const start_lnum = start.line + 1
        const end_lnum = end.line + 1

        const start_line = getbufline(bufnr, start_lnum)[0]
        const end_line = getbufline(bufnr, end_lnum)[0]

        const text_before = strpart(start_line, 0, start.character)
        const text_after = strpart(end_line, end.character)

        newLines[0] = text_before .. newLines[0]
        newLines[-1] = newLines[-1] .. text_after

        if end_lnum > start_lnum
            deletebufline(bufnr, start_lnum + 1, end_lnum)
        endif

        setbufline(bufnr, start_lnum, newLines[0])

        if len(newLines) > 1
            appendbufline(bufnr, start_lnum, newLines[1 : ])
        endif
    endfor

enddef



export def SingleFileDiff(uri: string, list: list<dict<any>>): string
    const bufnr = utils.EnsureBuffer(uri)
    var sorted = sort(list, SortEdits)

    var lines = getbufline(bufnr, 1, "$")
    const oldLines = copy(lines)

    for i in sorted
        const start = i.range.start
        const end = i.range.end
        var newLines = split(i.newText, '\n', 1)

        const start_lnum = start.line + 1
        const end_lnum = end.line + 1

        const start_line = getbufline(bufnr, start_lnum)[0]
        const end_line = getbufline(bufnr, end_lnum)[0]

        const text_before = strpart(start_line, 0, start.character)
        const text_after = strpart(end_line, end.character)

        newLines[0] = text_before .. newLines[0]
        newLines[-1] = newLines[-1] .. text_after

        
        lines = lines[ : start.line - 1] + newLines + lines[end.line + 1 :]
    endfor
    return diff(oldLines, lines)
enddef
