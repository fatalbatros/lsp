"Configuration 
if !exists("g:lsp")
  let g:lsp = {}
endif

if !has_key(g:lsp, 'typescript')
  let g:lsp['typescript'] = {
    \'cmd': ['typescript-language-server','--stdio'],
  \}
endif

if !has_key(g:lsp, 'cairo')
  let g:lsp['cairo'] = {
    \'cmd': ['scarb','cairo-language-server','/C','--node-ipc'],
  \}
endif


let s:opt = {
  \'exit_cb': 's:LspExit',
  \'out_cb': 's:LspStdout',
  \'err_cb': 's:LspStderr',
  \'noblock': 1,
  \'in_mode': 'lsp',
  \'out_mode': 'lsp',
\}

let s:capabilities = {
  \'workspace' : {},
  \'textDocument': {
    \'hover': {
      \'dynamicRegistration': v:false,
      \'contentFormat': ['plaintext','markdown']
    \},
    \'syncrhonization': {
      \'dynamicRegistration': v:false,
      \'willSaveWaitUntil':v:false,
      \'willSave': v:false,
      \'didSave': v:true
    \},
    \'publishDiagnostics': {
      \'relatedInformation': v:true,
      \'versionSuport': v:true,
      \'dynamicRegistration': v:false,
    \},
  \},
\}


function! LspStart() abort
  "start and restart the server
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
  let job_id = job_start(cmd,s:opt)
  let g:lsp[&filetype]['job_id'] = job_id
  let g:lsp[&filetype]['channel'] = job_getchannel(job_id)
  let g:lsp[&filetype]['files'] = {}
  let g:diagnostics = {}
  call s:LspInit()
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

def s:LspStdout(channel: channel, data: dict<any>)
  if has_key(data, 'method')
    if data['method'] == 'textDocument/publishDiagnostics'
      s:publishDiagnosticsCB(data['params'])
      return
    endif
  endif
  echom data
enddef

def s:publishDiagnosticsCB(params: dict<any>)
  var uri = params['uri']
  if bufexists(strpart(uri, 7))
    g:diagnostics[uri] = params['diagnostics']
    g:ParseDiagnostics()
  endif
enddef

function! s:LspStderr(channel, data) abort
  echom 'Error'
  echom a:data
endfunction

function! s:LspExit(job_id, exit_code) abort
  echom 'LSP exited with status: ' . a:exit_code
endfunction

function! s:LspInit() abort
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
  call ch_sendexpr(g:lsp[&filetype]['channel'], request, {'callback':'s:initCallback'})
endfunction

function! s:initCallback(channel,response) abort
  let g:init_response = a:response
  if has_key(a:response,'result') && has_key(a:response['result'],'capabilities')
    let g:capabilities = a:response['result']['capabilities']
    call ch_sendexpr(a:channel, {'method':'initialized', 'params':{}})
  endif

  execute 'au filetype ' . &filetype . ' call SetupBuffer("' . &filetype . '")'
  let l:filetype = &filetype
  bufdo call g:EnsureStart(l:filetype)
endfunction


