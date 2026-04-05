vim9script

import autoload "lsp/sync.vim" as sync
import autoload "diagnostic.vim" as diag
import autoload "utils.vim" as utils

import autoload "methods/hover.vim" as hov
import autoload "methods/definition.vim" as def
import autoload "methods/completion.vim" as comp
import autoload "methods/rename.vim" as rename
import autoload "methods/actions/quickfix.vim" as qf
import autoload "methods/actions/format.vim" as fmt


def SetLocal()
    setlocal omnifunc=comp.OmniLsp

    nnoremap <silent><buffer> K <Cmd>call <SID>hov.HoverOrPreview()<CR>
    nnoremap <silent><buffer> gd <Cmd>call <SID>def.Definition()<CR>
    nnoremap <silent><buffer> <space>w <Cmd>call <SID>sync.ForceSync()<CR>
    nnoremap <silent><buffer> ]d <Cmd>call <SID>diag.NextDiagnostic()<CR>
    nnoremap <silent><buffer> [d <Cmd>call <SID>diag.PreviousDiagnostic()<CR>
    nnoremap <silent><buffer> <F2> <Cmd>call <SID>rename.Rename()<CR>
    nnoremap <silent><buffer> <F3> <Cmd>call <SID>qf.QuickFix()<CR>

    augroup LspBufferAu
        autocmd! * <buffer>
        au bufdelete <buffer> call <SID>sync.DidClose(utils.PathToUri(expand('<afile>:p')))
        au bufenter <buffer> call <SID>diag.ParseDiagnostics()
        au bufenter <buffer> call <SID>sync.ForceSync()  
        au bufwritepost <buffer> call <SID>sync.ForceSync()  
        au insertleave <buffer> call <SID>sync.ForceSync()  
        au textchanged <buffer> call <SID>sync.ForceSync()  
    augroup END

    command! -buffer Fmt call <SID>fmt.Fmt()
enddef

def UnSetLocal()
    setlocal omnifunc&

    silent! nunmap <buffer> K
    silent! nunmap <buffer> gd
    silent! nunmap <buffer> <space>w
    silent! nunmap <buffer> ]d
    silent! nunmap <buffer> [d
    silent! nunmap <buffer> <F2>
    silent! nunmap <buffer> <F3>

    augroup LspBufferAu
        autocmd! * <buffer>
    augroup END

    delcommand -buffer Fmt
enddef


def SetupLocal() 
    const nr = bufnr()
    if getbufvar(nr, 'lsp_attached', v:false) | return | endif
    setbufvar(nr, 'lsp_attached', v:true) 
    
    SetLocal()
enddef

def CleanLocal()
    const nr = bufnr()
    if !getbufvar(nr, 'lsp_attached', v:false) | return | endif
    setbufvar(nr, 'lsp_attached', v:false) 
    diag.ClearDiagnostics()
    
    UnSetLocal()
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

    execute 'augroup LspAttach_' .. filetype
        execute 'au!'
        execute 'au filetype ' .. filetype .. ' call SetupLocal()'
    execute 'augroup END'
enddef

export def ClearFiletype(filetype: string) 
    const current = bufnr()

    for buf in getbufinfo()
        var nr = buf.bufnr
        if getbufvar(nr, '&filetype', '') != filetype
            continue
        endif

        sync.UnSyncUri(utils.PathToUri(buf.name))

        if nr == current 
            CleanLocal()
            continue
        endif

        execute 'au bufenter <buffer=' .. nr .. '> ++once call CleanLocal()'
    endfor

    execute 'augroup LspAttach_' .. filetype
        execute 'au!'
    execute 'augroup END'
enddef
