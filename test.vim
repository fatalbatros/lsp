let s:cmd = ['typescript-language-server','--stdio']
let s:opt = {
    \ 'exit_cb': 'LspExit',
    \ 'out_cb': 'LspStdout',
    \ 'err_cb': 'LspStderr',
    \ 'noblock': 1,
    \ 'in_mode': 'lsp',
    \ 'out_mode': 'lsp',
  \}

function LspStart()
  let b:job_id = job_start(s:cmd,s:opt)
  let b:info = job_info(b:job_id)
  let b:channel = job_getchannel(b:job_id)
endfunction

function LspStop()
  call job_stop(b:job_id)
  echom"done"
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
  echom'Exit'
  echom'LSP exited with status: ' . a:exit_code
endfunction

function! LspInit() abort
  echom 'initialize'
  let request = {
    \   'method': 'initialize',
    \   'params': {
    \     'processId': getpid(),
    \     'clientInfo': { 'name': 'lsp-joel', 'version':'0' },
    \     'capabilities': {'textDocument': {'hover':{'dynamicRegistration': v:false}}},
    \     'rootUri': '/home/alba/proyects/lsp/',
    \     'rootPath': '/home/alba/proyects/lsp/',
    \     'trace': 'off',
    \   },
  \ }
  call ch_sendexpr(b:channel, request, {'callback':'InitCallback'})
endfunction

function! InitCallback(channel,response) abort
  echom 'Callback'
  echom a:channel
  echom a:response
  if has_key(a:response,'result') && has_key(a:response['result'],'capabilities')
    call ch_sendexpr(b:channel, {'method':'initialized', 'params':{}})
  endif
endfunction



call LspStart()
call LspInit()

"call LspStop()

