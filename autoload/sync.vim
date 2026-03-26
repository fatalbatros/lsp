vim9script

import autoload "utils.vim" as utils

export def DidClose(uri: string)
    if !has_key(g:lsp_synchronized, uri) | return | endif

    const didClose = {
        'method': 'textDocument/didClose',
        'params': {
            'textDocument': {
                'uri': uri,
            },
        },
    }
  
    const filetype = g:lsp_synchronized[uri]['filetype']
    ch_sendexpr(g:lsp[filetype]['channel'], didClose)

    const bufnr = g:lsp_synchronized[uri]['buffer']
    setbufvar(bufnr, 'diagnostics', v:null)
    setbufvar(bufnr, 'sync_changedtick', v:null)

    unlet g:lsp_synchronized[uri]
    if has_key(g:diagnostics, uri)
        unlet g:diagnostics[uri] 
    endif
enddef



def DidOpen(uri: string)
    const filetype = g:lsp_synchronized[uri]['filetype']
    const didOpen = {
        'method': 'textDocument/didOpen',
        'params': {
            'textDocument': {
                'uri': uri,
                'languageId': filetype, 
                'version': 1,
                'text': utils.GetLines(uri),
            },
        },
    }
    ch_sendexpr(g:lsp[filetype]['channel'], didOpen)
enddef


def DidChange(uri: string, version: number)
    var filetype = g:lsp_synchronized[uri]['filetype']
    const didChange = {
        'method': 'textDocument/didChange',
            'params': {
                'textDocument': {
                    'uri': uri,
                    'version':  version,
                },
            'contentChanges': [{'text': utils.GetLines(uri) }],
        },
    }
    ch_sendexpr(g:lsp[filetype]['channel'], didChange)
enddef


export def ForceSync()
  const uri = utils.GetCurrentUri()
  ForceSyncUri(uri)
enddef

export def ForceSyncUri(uri: string)
    const bufnr = utils.EnsureBuffer(uri)
    const filetype = getbufvar(bufnr, '&filetype')
    const changedtick = getbufvar(bufnr, 'changedtick')

    if !has_key(g:lsp_synchronized, uri)
        g:lsp_synchronized[uri] = {'buffer': bufnr, 'version': 1, 'filetype': filetype}
        setbufvar(bufnr, 'sync_changedtick', changedtick)
        DidOpen(uri)
        return
    endif 

    if getbufvar(bufnr, 'sync_changedtick') != changedtick
        var new_version = g:lsp_synchronized[uri]['version'] + 1
        g:lsp_synchronized[uri]['version'] = new_version
        setbufvar(bufnr, 'sync_changedtick', changedtick)
        DidChange(uri, new_version)
    endif
enddef
