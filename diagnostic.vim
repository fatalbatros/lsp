let s:hiType = {
  \'diagnosticError': 'WarningMsg',
  \'diagnosticErrorInline': 'WarningMsg',
  \'diagnosticWarning': 'Changed',
  \'diagnosticWarningInline': 'Changed',
\}

call prop_type_add('diagnosticError',{'highlight': s:hiType['diagnosticError']})
call prop_type_add('diagnosticErrorInline',{ 'overrride': v:false})
call prop_type_add('diagnosticWarning',{'highlight': s:hiType['diagnosticWarning']})
call prop_type_add('diagnosticWarningInline',{ 'override': v:false})
call prop_type_add('diagnosticMark',{'priority': -1, 'override': v:false})


def g:ParseDiagnostics()
  var uri = 'file://' .. expand("%:p")
  if !exists("g:diagnostics") | return | endif
  if !has_key(g:diagnostics, uri)
    return
  endif
  call prop_clear(1, line('$'))
  b:diag = g:diagnostics[uri]
  b:diagnostic_text = {}

  var idx = 1
  for i in b:diag
    #the pad is temporal to see first the error and then the warnings
    var pad = 1
    var type = 'diagnosticWarning'
    if i['severity'] == 1
      pad = 0
      type = 'diagnosticError'
    endif
    var line = i['range']['start']['line'] + 1
    var char = i['range']['start']['character'] + 1
    var text = i['message']
    prop_add(line, 0, {'type': type, 'text': text, 'text_align': 'right', 'text_wrap': 'truncate'})
    prop_add(line, char + pad, {'type': type .. 'Inline' })
    prop_add(line, char + pad, {'type': 'diagnosticMark', 'id': idx })
    b:diagnostic_text[idx] = {'text': text, 'highlight': hiType[type] }
    idx += 1
  endfor
enddef

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
  

