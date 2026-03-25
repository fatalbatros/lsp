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
