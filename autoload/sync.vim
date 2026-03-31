vim9script

import autoload "utils.vim" as utils
import autoload "lsp/request.vim" as Request

export def DidClose(uri: string)
    if !has_key(g:lsp_synchronized, uri) | return | endif

    const request = {
        'method': 'textDocument/didClose',
        'params': {
            'textDocument': {
                'uri': uri,
            },
        },
    }
  
    const filetype = g:lsp_synchronized[uri]['filetype']
    Request.Send(filetype, request)
enddef



def DidOpen(uri: string)
    const filetype = g:lsp_synchronized[uri]['filetype']
    const request = {
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
    Request.Send(filetype, request)
enddef


def DidChange(uri: string, version: number)
    var filetype = g:lsp_synchronized[uri]['filetype']
    const request = {
        'method': 'textDocument/didChange',
            'params': {
                'textDocument': {
                    'uri': uri,
                    'version':  version,
                },
            'contentChanges': [{'text': utils.GetLines(uri) }],
        },
    }
    Request.Send(filetype, request)
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

export def UnSyncUri(uri: string)
    if !has_key(g:lsp_synchronized, uri) | return | endif
    const filetype = g:lsp_synchronized[uri]['filetype']
    
    const job = get(g:lsp[filetype], 'job_id', v:null)

    if job != v:null && ch_status(job) == 'open'
        DidClose(uri)
    endif

    const bufnr = g:lsp_synchronized[uri]['buffer']

    if bufexists(bufnr)
        setbufvar(bufnr, 'diagnostics', v:null)
        setbufvar(bufnr, 'sync_changedtick', v:null)
    endif

    unlet g:lsp_synchronized[uri]
    if has_key(g:diagnostics, uri)
        unlet g:diagnostics[uri] 
    endif
enddef
