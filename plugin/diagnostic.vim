vim9script

import "./utils.vim" as utils

var hiType = {
  'diagnosticError': 'ErrorMsg',
  'diagnosticErrorInline': 'ErrorMsg',
  'diagnosticWarning': 'WarningMsg',
  'diagnosticWarningInline': 'WarningMsg',
}

if empty(prop_type_get('diagnosticError'))
  prop_type_add('diagnosticError', {'highlight': hiType['diagnosticError']})
endif

if empty(prop_type_get('diagnosticErrorInline'))
  prop_type_add('diagnosticErrorInline', { 'override': v:false})
endif

if empty(prop_type_get('diagnosticWarning'))
  prop_type_add('diagnosticWarning', {'highlight': hiType['diagnosticWarning']})
endif

if empty(prop_type_get('diagnosticWarningInline'))
  prop_type_add('diagnosticWarningInline', { 'override': v:false})
endif

if empty(prop_type_get('diagnosticMark'))
  prop_type_add('diagnosticMark', {'priority': -1, 'override': v:false})
endif

def ClearDiagnostics() 
    call prop_clear(1, line('$'), {'type': 'diagnosticError'})
    call prop_clear(1, line('$'), {'type': 'diagnosticWarning'})
    call prop_clear(1, line('$'), {'type': 'diagnosticErrorInline'})
    call prop_clear(1, line('$'), {'type': 'diagnosticWarningInline'})
    call prop_clear(1, line('$'), {'type': 'diagnosticMark'})
enddef

export def PublishDiagnosticsCB(params: dict<any>)
  var uri = utils.ParseUri(params['uri'])
  var file = utils.UriToPath(uri)
  if !file | return | endif
  if !bufexists(file) | return | endif
  g:diagnostics[uri] = params['diagnostics']
  ParseDiagnostics()
enddef

export def ParseDiagnostics()
    if !g:show_diagnostic | return | endif
    const uri = utils.GetCurrentUri()
    if !has_key(g:diagnostics, uri)
        return
    endif
    ClearDiagnostics()
    b:diagnostics = g:diagnostics[uri]
    b:diagnostic_text = {}

    var seen = {}
    var idx = 1

    # I want to always have a mark for diagnostics but only show a line text  for
    # diagnostics that have the most severity.
    for i in b:diagnostics
        var severity = get(i, 'severity', 1)
        var type = severity == 1 ? 'diagnosticError' : 'diagnosticWarning'
        var line = i.range.start.line + 1
        var char = i.range.start.character + 1

        var max_col = strlen(getline(line))
        if char > max_col
            continue
        endif

        var text = i.message

        prop_add(line, char, {
            'type': 'diagnosticMark',
            'id': idx
        })

        b:diagnostic_text[idx] = {
            'text': text,
            'highlight': hiType[type]
        }

        idx += 1

        if has_key(seen, line) && seen[line] <= severity | continue | endif
        seen[line] = severity

        var props = prop_list(line, {'types': ['diagnosticError', 'diagnosticWarning']})
        if empty(props)
            prop_add(line, 0, {
                'type': type,
                'text': text,
                'text_align': 'right',
                'text_wrap': 'truncate'
            })
        endif

        prop_add(line, char, {
            'type': type .. 'Inline',
            'priority': severity == 1 ? 100 : 50
        })

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
  cursor(line, col) 
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
