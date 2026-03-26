vim9script

export def ParseUri(uri: string): string
    return substitute(uri, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
enddef

export def PathToUri(path: string): string 
    return 'file://' .. fnamemodify(path, ':p')
enddef

export def UriToPath(uri: string): string
   return matchstr(ParseUri(uri), 'file://\zs.*')
enddef

export def GetCurrentUri(): string
    return PathToUri(expand("%:p"))
enddef

export def EnsureBuffer(uri: string): number
  var path = UriToPath(uri)
  var bufnr = bufnr(path)
  if bufnr == -1
    bufnr = bufnr(bufadd(path))
  endif
  bufload(bufnr)
  return bufnr
enddef

export def GetLines(uri: string):  string
  const lines = getbufline(bufnr(UriToPath(uri)), 1, '$')
  return join(lines, "\n")
enddef


export def FindRootDir(start: string, filetype: string): string
    var markers = []
    var root = ''

    if has_key(g:lsp, filetype)
        markers = get(g:lsp[filetype], 'root_markers', [])
    endif

    sort(markers, (a, b) => a.priority - b.priority)
    const path = fnamemodify(start, ":p:h") .. ";"

    for marker in markers
        if marker.type == 'dir'
            root = fnamemodify(finddir(marker.name, path), ":p:h:h")
        elseif marker.type == 'file'
            root = fnamemodify(findfile(marker.name, path), ":p:h")
        endif

        if root == '' | continue | endif

        return root .. '/'
    endfor

    return fnamemodify(start, ":p:h") .. '/'
enddef


export def EchoOk(message: string)
    echohl Added
    echo message
    echohl Normal
enddef

export def EchoError(message: string)
    echohl ErrorMsg
    echo message
    echohl Normal
enddef
