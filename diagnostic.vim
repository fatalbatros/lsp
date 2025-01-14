
call prop_type_add('diagnostic',{'highlight':'WarningMsg'})

function! ParseDiagnostics() abort
  if g:diagnostics['uri'] != 'file://' . expand("%:p")
    return
  endif

  let b:diagnostics = g:diagnostics['diagnostics']
  for i in b:diagnostics
    let l:line = i['range']['start']['line'] + 1
    let l:char = i['range']['start']['character']
    let l:text = i['message']
    call prop_add(l:line,0,{'type': 'diagnostic','id': l:idx, 'text':l:text,'text_align':'right', 'text_wrap':'truncate'})
  endfor
endfunction

