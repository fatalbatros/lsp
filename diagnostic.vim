call prop_type_add('diagnostic',{'highlight':'WarningMsg'})
call prop_type_add('diagnostic_char',{'highlight':'WarningMsg'})

function! ParseDiagnostics() abort
  if g:diagnostics['uri'] != 'file://' . expand("%:p")
    return
  endif
  let b:diagnostic_text = {}
  call prop_clear(1,line('$'))

  let b:diag = g:diagnostics['diagnostics']
  let l:idx = 1
  for i in b:diag
    let l:line = i['range']['start']['line'] + 1
    let l:char = i['range']['start']['character'] + 1
    let l:text = i['message']
    call prop_add(l:line,0,{'type': 'diagnostic', 'text':l:text,'text_align':'right', 'text_wrap':'truncate'})
    call prop_add(l:line,l:char ,{'type': 'diagnostic_char','id': l:idx })
    let b:diagnostic_text[l:idx] = l:text
    let l:idx += 1
  endfor
endfunction

function! NextDiagnostic() abort
  let l:diag = prop_find({'type':'diagnostic_char','skipstart': v:true}, "f")
  if empty(l:diag) 
    echo "No more diagnostics"
    return
  endif
  call s:ShowDiagnostic(l:diag)
endfunction

function! PreviousDiagnostic() abort
  let l:diag = prop_find({'type':'diagnostic_char','skipstart': v:true}, "b")
  if empty(l:diag) 
    echo "No more diagnostics"
    return
  endif
  call s:ShowDiagnostic(l:diag)
endfunction

function! s:ShowDiagnostic(diagnostic) abort
  let l:line = a:diagnostic['lnum']
  let l:col = a:diagnostic['col']
  let l:id = a:diagnostic['id']
  let l:text = b:diagnostic_text[l:id]
  call setcursorcharpos(l:line,l:col) 
  let l:options = {
    \'pos': 'topleft',
    \'highlight':'WarningMsg',
    \'moved':'any',
  \}
  call popup_atcursor(l:text,l:options)
endfunction
  

nnoremap <silent> ]d :call NextDiagnostic()<CR>
nnoremap <silent> [d :call PreviousDiagnostic()<CR>
