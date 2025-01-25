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

def g:NextDiagnostic()
  var diag = prop_find({'type': 'diagnosticMark', 'skipstart': v:true}, "f")
  if empty(diag) 
    echo "No more diagnostics"
    return
  endif
  call s:ShowDiagnostic(diag)
enddef

def g:PreviousDiagnostic()
  var diag = prop_find({'type': 'diagnosticMark', 'skipstart': v:true}, "b")
  if empty(diag) 
    echo "No more diagnostics"
    return
  endif
  s:ShowDiagnostic(diag)
enddef

def s:ShowDiagnostic(diagnostic: dict<any>)
  var line = diagnostic['lnum']
  var col = diagnostic['col']
  var id = diagnostic['id']
  var text = b:diagnostic_text[id]['text']
  var hi = b:diagnostic_text[id]['highlight']
  setcursorcharpos(line, col) 
  var options = {
    'pos': 'topleft',
    'highlight': hi,
    'moved': 'any',
  }
  popup_atcursor(text, options)
enddef
  

