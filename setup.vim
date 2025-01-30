vim9script

import "./sync.vim"

def g:EnsureStart(type: string)
  var buf = bufnr('%')
  execute 'bufdo call g:SetupBuffer("' ..  type .. '")'
 execute 'buffer ' .. buf
enddef

def g:SetupBuffer(type: string)
  if &filetype != type | return | endif
  augroup LspBuferAu
    autocmd! * <buffer>
    au bufdelete <buffer> call DidClose(expand('<afile>:p'))
    au bufenter <buffer> call ForceSync()  
    au bufwritepost <buffer> call ForceSync()  
  augroup END
  g:ForceSync()
  Maps()
enddef

def Maps()
  nnoremap <silent><buffer> K :call Hover()<CR>
  nnoremap <silent><buffer> gd :call Definition()<CR>
  nnoremap <silent><buffer> <space>w :call ForceSync()<CR>
  nnoremap <silent><buffer> ]d :call NextDiagnostic()<CR>
  nnoremap <silent><buffer> [d :call PreviousDiagnostic()<CR>
enddef
