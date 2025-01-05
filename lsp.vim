if !exists("g:lsp")
  let g:lsp = {}
endif

if !has_key(g:lsp, 'typescript')
  let g:lsp['typescript'] = {
    \'cmd': ['typescript-language-server','--stdio'],
  \}
endif

let s:opt = {
    \ 'exit_cb': 'LspExit',
    \ 'out_cb': 'LspStdout',
    \ 'err_cb': 'LspStderr',
    \ 'noblock': 1,
    \ 'in_mode': 'lsp',
    \ 'out_mode': 'lsp',
  \}

let s:capabilities = {
  \'workspace' : {},
  \'textDocument': {
    \'hover': {
      \'dynamicRegistration': v:false,
      \'contentFormat': ['plaintext']
    \},
    \'syncrhonization': {
      \'dynamicRegistration': v:false,
      \'willSaveWaitUntil':v:false,
      \'willSave': v:false,
      \'didSave': v:true
    \},
  \},
\}

function! LspStart() abort
  if !has_key(g:lsp, &filetype)
    echoerr 'Lsp for ' . &filetype . ' not set'
    return
  elseif !has_key(g:lsp[&filetype],'cmd')
    echoerr 'Lsp start command not defined for ' . &filetype
    return
  elseif has_key(g:lsp[&filetype], 'job_id') 
    if ch_status(g:lsp[&filetype]['job_id']) == 'open'
      echoerr 'Lsp for ' . &filetype . ' is running'
      return
    else
      call job_stop(g:lsp[&filetype]['job_id'])
    endif
  endif

  let cmd = g:lsp[&filetype]['cmd']
  call Log('Starting Lsp', &filetype, cmd)
  let job_id = job_start(cmd,s:opt)
  let g:lsp[&filetype]['job_id'] = job_id
  let g:lsp[&filetype]['channel'] = job_getchannel(job_id)
  call Log("Lsp Started", &filetype, job_id)
  call LspInit()
endfunction

function! LspStop()
  if has_key(g:lsp, &filetype) && has_key(g:lsp[&filetype],'job_id')
    call job_stop(g:lsp[&filetype]['job_id'])
    unlet g:lsp[&filetype]['job_id']
    unlet g:lsp[&filetype]['channel']
  else
    echom 'Lsp server for ' . &filetype . ' not found'
  endif
endfunction

function! LspStdout(channel, data) abort
  echom 'Out'
  echom a:channel
  echom a:data
endfunction

function! LspStderr(channel, data) abort
  echom 'Error'
  echom a:data
endfunction

function! LspExit(job_id, exit_code) abort
  echom 'LSP exited with status: ' . a:exit_code
endfunction

function! LspInit() abort
  echom 'initialize'
  let request = {
    \   'method': 'initialize',
    \   'params': {
    \     'processId': getpid(),
    \     'clientInfo': { 'name': 'lsp-joel', 'version':'0' },
    \     'capabilities': s:capabilities,
    \     'rootPath':expand("%:p:h"),
    \     'rootURI':'file://'.expand("%:p:h").'/',
    \     'trace': 'off',
    \   },
  \ }
  call ch_sendexpr(g:lsp[&filetype]['channel'], request, {'callback':'_initCallback'})
endfunction

function! _initCallback(channel,response) abort
  if has_key(a:response,'result') && has_key(a:response['result'],'capabilities')
    call Log("Lsp Initializated")
    call ch_sendexpr(a:channel, {'method':'initialized', 'params':{}})
    call Log("Sending Initializated Notification")
  else
    call Log("Initialiation Error", a:response)
  endif
endfunction

function DidOpen() abort
  let l:didOpen = {
    \'method':'textDocument/didOpen',
    \'params':{
      \'textDocument': {
        \'uri':'file://' . expand("%:p"),
        \'languageId': 'typescript', 
        \'version': 1,
        \'text': Get_Lines(),
      \},
    \},
  \}
  call ch_sendexpr(g:lsp[&filetype]['channel'],l:didOpen)
  call Log ('Sending /didOpen notification ', l:didOpen)
endfunction

"call LspStart()
"call LspInit()
"call DidOpen()
"call Hover()
"call LspStop()
"

function! Get_Lines() abort
    let l:lines = getbufline(bufnr(), 1, '$')
    return join(l:lines, "\n")
endfunction


let g:log_lsp = expand("%:p:h") . '/log.log'
function! Log(header,...) abort
    if !empty(g:log_lsp)
        call writefile([strftime('%Y-%m-%d %T') . ' -> '. a:header .' : '. string(a:000)], g:log_lsp, 'a')
    endif
endfunction
