vim9script

import autoload "sync.vim" as sync
import autoload "diagnostic.vim" as diag
import autoload "utils.vim" as utils

import autoload "methods/hover.vim" as hov
import autoload "methods/definition.vim" as def
import autoload "methods/completion.vim" as comp
import autoload "methods/rename.vim" as rename
import autoload "methods/code_actions.vim" as actions

def SetLocalOptions()
    setlocal omnifunc=comp.OmniLsp
enddef

def SetLocalMaps()
  nnoremap <silent><buffer> K <Cmd>call <SID>hov.HoverOrPreview()<CR>
  nnoremap <silent><buffer> gd <Cmd>call <SID>def.Definition()<CR>
  nnoremap <silent><buffer> <space>w <Cmd>call <SID>sync.ForceSync()<CR>
  nnoremap <silent><buffer> ]d <Cmd>call <SID>diag.NextDiagnostic()<CR>
  nnoremap <silent><buffer> [d <Cmd>call <SID>diag.PreviousDiagnostic()<CR>
  nnoremap <silent><buffer> <F2> <Cmd>call <SID>rename.Rename()<CR>
  nnoremap <silent><buffer> <F3> <Cmd>call <SID>actions.CodeActions()<CR>
enddef

def SetLocalAu()
    augroup LspBuferAu
        autocmd! * <buffer>
        au bufdelete <buffer> call <SID>sync.DidClose(utils.PathToUri(expand('<afile>:p')))
        au bufenter <buffer> call <SID>diag.ParseDiagnostics()
        au bufenter <buffer> call <SID>sync.ForceSync()  
        au bufwritepost <buffer> call <SID>sync.ForceSync()  
        au insertleave <buffer> call <SID>sync.ForceSync()  
        au textchanged <buffer> call <SID>sync.ForceSync()  
    augroup END
enddef


def SetupLocal() 
    const nr = bufnr()
    if getbufvar(nr, 'lsp_attached', v:false) | return | endif
    setbufvar(nr, 'lsp_attached', v:true) 
    
    SetLocalOptions()
    SetLocalAu()
    SetLocalMaps()
enddef

export def SetupFiletype(filetype: string) 
    const current = bufnr()

    for buf in getbufinfo()
        var nr = buf.bufnr
        if getbufvar(nr, '&filetype', '') != filetype
            continue
        endif

        sync.ForceSyncUri(utils.PathToUri(buf.name))

        if nr == current 
            SetupLocal()
            continue
        endif

        execute 'au bufenter <buffer=' .. nr .. '> ++once call SetupLocal()'
    endfor

    augroup LspAttach
        execute 'au filetype ' .. filetype .. ' call SetupLocal()'
    augroup END
enddef
