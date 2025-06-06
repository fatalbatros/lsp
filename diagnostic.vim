vim9script

var hiType = {
  'diagnosticError': 'ErrorMsg',
  'diagnosticErrorInline': 'ErrorMsg',
  'diagnosticWarning': 'WarningMsg',
  'diagnosticWarningInline': 'WarningMsg',
}

prop_type_add('diagnosticError', {'highlight': hiType['diagnosticError']})
prop_type_add('diagnosticErrorInline', { 'overrride': v:false})
prop_type_add('diagnosticWarning', {'highlight': hiType['diagnosticWarning']})
prop_type_add('diagnosticWarningInline', { 'override': v:false})
prop_type_add('diagnosticMark', {'priority': -1, 'override': v:false})


export def PublishDiagnosticsCB(params: dict<any>)
  var uri = params['uri']
  var file = matchstr(uri, 'file://\zs.*')
  if !file | return | endif
  if !bufexists(file) | return | endif
  g:diagnostics[uri] = params['diagnostics']
  ParseDiagnostics()
enddef

export def ParseDiagnostics()
  if !g:show_diagnostic | return | endif
  var uri = 'file://' .. expand("%:p")
  if !has_key(g:diagnostics, uri)
    return
  endif
  call prop_clear(1, line('$'))
  b:diagnostics = g:diagnostics[uri]
  b:diagnostic_text = {}

  var idx = 1
  for i in b:diagnostics
    # the pad is temporal to see first the error and then the warnings
    var pad = 1
    var type = 'diagnosticWarning'
    if i['severity'] == 1
      pad = 0
      type = 'diagnosticError'
    endif
    var line = i['range']['start']['line'] + 1
    var char = i['range']['start']['character'] + 1
    var text = i['message']
    var props = prop_list(line)
    # This is for showing only a single message inline. 
    # TODO: Be shure to show a high serverity error
    if empty(props)
        prop_add(line, 0, {'type': type, 'text': text, 'text_align': 'right', 'text_wrap': 'truncate'})
    endif
    prop_add(line, char + pad, {'type': type .. 'Inline' })
    prop_add(line, char + pad, {'type': 'diagnosticMark', 'id': idx })
    b:diagnostic_text[idx] = {'text': text, 'highlight': hiType[type] }
    idx += 1
  endfor
enddef

export def NextDiagnostic()
  var diag = prop_find({'type': 'diagnosticMark', 'skipstart': v:true}, "f")
  if empty(diag) 
    diag = prop_find({'type': 'diagnosticMark', 'skipstart': v:false, 'lnum': 1, 'col': 1}, "f")
    if empty(diag)
      echo "No more diagnostics"
      return
    endif
  endif
  call ShowDiagnostic(diag)
enddef

export def PreviousDiagnostic()
  var diag = prop_find({'type': 'diagnosticMark', 'skipstart': v:true}, "b")
  if empty(diag) 
    var line = getpos('$')[1]
    var col = getpos('$')[2]
    diag = prop_find({'type': 'diagnosticMark', 'skipstart': v:false, 'lnum': line, 'col': col}, "b")
    if empty(diag)
      echo "No more diagnostics"
      return
    endif
  endif
  ShowDiagnostic(diag)
enddef

def ShowDiagnostic(diagnostic: dict<any>)
  var line = diagnostic['lnum']
  var col = diagnostic['col']
  var id = diagnostic['id']
  var text = b:diagnostic_text[id]['text']
  var hi = b:diagnostic_text[id]['highlight']
  setcursorcharpos(line, col) 
  var options = {
    'pos': 'topleft',
    'borderhighlight': ['LineNr'],
    'highlight': hi,
    'moved': 'any',
    'border': [1, 1, 1, 1],
    'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└'], 
  }
  popup_atcursor(text, options)
enddef
  
