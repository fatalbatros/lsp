vim9script

import "./sync.vim" as sync
import "./hover.vim" as hov
import "./definition.vim" as def
import "./diagnostic.vim" as diag
import "./completion.vim" as comp

set completeopt=menu,menuone,popuphidden
set omnifunc=comp.OmniLsp

def Maps()
  nnoremap <silent><buffer> K :call <SID>hov.Hover()<CR>
  nnoremap <silent><buffer> gd :call <SID>def.Definition()<CR>
  nnoremap <silent><buffer> <space>w :call <SID>sync.ForceSync()<CR>
  nnoremap <silent><buffer> ]d :call <SID>diag.NextDiagnostic()<CR>
  nnoremap <silent><buffer> [d :call <SID>diag.PreviousDiagnostic()<CR>
enddef

def g:EnsureStart(type: string)
  var buf = bufnr('%')
  execute 'bufdo call ' .. expand('<SID>') .. 'SetupBuffer("' ..  type .. '")'
 execute 'buffer ' .. buf
enddef

def g:SetupBuffer(type: string)
  if &filetype != type | return | endif
  augroup LspBuferAu
    autocmd! * <buffer>
    au bufdelete <buffer> call <SID>sync.DidClose(expand('<afile>:p'))
    au bufenter <buffer> call <SID>diag.ParseDiagnostics()
    au bufenter <buffer> call <SID>sync.ForceSync()  
    au bufwritepost <buffer> call <SID>sync.ForceSync()  
  augroup END
  sync.ForceSync()
  Maps()
enddef
