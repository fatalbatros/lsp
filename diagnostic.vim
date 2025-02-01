let s:hiType = {
  \'diagnosticError': 'ErrorMsg',
  \'diagnosticErrorInline': 'ErrorMsg',
  \'diagnosticWarning': 'WarningMsg',
  \'diagnosticWarningInline': 'WarningMsg',
\}

call prop_type_add('diagnosticError',{'highlight': s:hiType['diagnosticError']})
call prop_type_add('diagnosticErrorInline',{ 'overrride': v:false})
call prop_type_add('diagnosticWarning',{'highlight': s:hiType['diagnosticWarning']})
call prop_type_add('diagnosticWarningInline',{ 'override': v:false})
call prop_type_add('diagnosticMark',{'priority': -1, 'override': v:false})


function! ParseDiagnostics() abort
  if !g:show_diagnostic | return | endif
  let l:uri = 'file://' . expand("%:p")
  if !exists("g:diagnostics") | return | endif
  if !has_key(g:diagnostics, l:uri)
    return
  endif
  call prop_clear(1,line('$'))
  let b:diag = g:diagnostics[l:uri]

  let b:diagnostic_text = {}

  let l:idx = 1
  for i in b:diag
    "the pad is temporal to see first the error and then the warnings
    let l:pad = 1
    let l:type = 'diagnosticWarning'
    if i['severity'] == 1
      let l:pad = 0
      let l:type = 'diagnosticError'
    endif
    let l:line = i['range']['start']['line'] + 1
    let l:char = i['range']['start']['character'] + 1
    let l:text = i['message']
    call prop_add(l:line,0,{'type': l:type , 'text':l:text,'text_align':'right', 'text_wrap':'truncate'})
    call prop_add(l:line,l:char + l:pad ,{'type': l:type . 'Inline' })
    call prop_add(l:line,l:char + l:pad,{'type': 'diagnosticMark','id': l:idx })
    let b:diagnostic_text[l:idx] = {'text': l:text, 'highlight': s:hiType[l:type] }
    let l:idx += 1
  endfor
endfunction

function! NextDiagnostic() abort
  let l:diag = prop_find({'type':'diagnosticMark','skipstart': v:true}, "f")
  if empty(l:diag) 
    echo "No more diagnostics"
    return
  endif
  call s:ShowDiagnostic(l:diag)
endfunction

function! PreviousDiagnostic() abort
  let l:diag = prop_find({'type':'diagnosticMark','skipstart': v:true}, "b")
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
  let l:text = b:diagnostic_text[l:id]['text']
  let l:hi = b:diagnostic_text[l:id]['highlight']
  call setcursorcharpos(l:line,l:col) 
  let l:options = {
    \'pos': 'topleft',
    \'highlight':l:hi,
    \'moved':'any',
  \}
  call popup_atcursor(l:text,l:options)
endfunction
  

