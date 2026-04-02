vim9script 

import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils

# changes ussually comes in from changes: {[uri: ]: TextEdit[]}. When not, I
# format the other possible options to behave like this
export def ApplyChanges(change: dict<any>) 
    const changes = edit.changes
    for [uri, list]  in items(changes)
        AppyArrayTextEdit(uri, list)
    endfor
enddef

def SortEdits(a: dict<any>, b: dict<any>): number
    if a.range.start.line != b.range.start.line
        return b.range.start.line - a.range.start.line
    endif
    return b.range.start.character - a.range.start.character
enddef

# Apply to a single file and array of TextEdit.
export def ApplyArrayTextEdit(uri: string, list: list<dict<any>>)
    var sorted = sort(list, SortEdits)
    for textEdit in sorted
        ApplyTextEdit(uri, textEdit)
    endfor
    sync.ForceSyncUri(uri)
enddef

# Apply a single TextEdit: { range: Range, newText: string}
def ApplyTextEdit(uri: string, textEdit: dict<any>)
    const bufnr = utils.EnsureBuffer(uri)

    const start = textEdit.range.start
    const end = textEdit.range.end

    const start_lnum = start.line + 1
    const end_lnum = end.line + 1

    const start_line = getbufline(bufnr, start_lnum)[0]

    const text_before = strpart(start_line, 0, start.character)

    var text_after = ''
    if end.character > 0
        const end_line = getbufline(bufnr, end_lnum)[0]
        text_after = strpart(end_line, end.character)
    endif

    var newLines = split(textEdit.newText, '\n', 1)

    newLines[0] = text_before .. newLines[0]
    newLines[-1] = newLines[-1] .. text_after

    if end_lnum > start_lnum
        if end.character == 0
            deletebufline(bufnr, start_lnum + 1, end_lnum - 1)
        else
            deletebufline(bufnr, start_lnum + 1, end_lnum)
        endif
    endif

    keepjumps keepmarks noautocmd setbufline(bufnr, start_lnum, newLines[0])

    if len(newLines) > 1
        keepjumps keepmarks noautocmd appendbufline(bufnr, start_lnum, newLines[1 : ])
    endif
enddef


export def SingleFileDiff(uri: string, list: list<dict<any>>): string
    const bufnr = utils.EnsureBuffer(uri)
    var sorted = sort(list, SortEdits)

    var lines = getbufline(bufnr, 1, "$")
    const oldLines = copy(lines)

    for i in sorted
        const start = i.range.start
        const end = i.range.end

        const start_lnum = start.line + 1
        const end_lnum = end.line + 1

        const start_line = getbufline(bufnr, start_lnum)[0]

        const text_before = strpart(start_line, 0, start.character)

        var text_after = ''
        if end.character > 0
            const end_line = getbufline(bufnr, end_lnum)[0]
            text_after = strpart(end_line, end.character)
        endif

        var newLines = split(i.newText, '\n', 1)

        newLines[0] = text_before .. newLines[0]
        newLines[-1] = newLines[-1] .. text_after

        
        lines = lines[ : start.line - 1] + newLines + lines[end.line + 1 :]
    endfor
    return diff(oldLines, lines)
enddef
