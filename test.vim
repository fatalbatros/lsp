"notes: Everithing is mocked, open tpyscript/src/main as bufer number 2.

let s:cmd = ['typescript-language-server','--stdio']
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
      \'contentFormat': ['markdown','plaintext']
    \},
    \'syncrhonization': {
      \'dynamicRegistration': v:false,
      \'willSaveWaitUntil':v:false,
      \'willSave': v:false,
      \'didSave': v:true
    \},
  \},
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
    \     'capabilities': s:capabilities,
    \     'rootPath': '/home/alba/proyects/lsp/typescript/',
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


function Hover() abort
  let l:hover = {
    \ 'method':'textDocument/hover',
    \ 'params': {
    \ 'textDocument': {'uri': 'file:///home/alba/proyects/lsp/typescript/src/main.ts'},
    \ 'position': {'line': 2,
        \ 'character': 15
      \}
    \ }
  \ }
  call ch_sendexpr(b:channel,l:hover,{'callback':'HoverCallback'})
endfunction 

function! HoverCallback(channel,response) abort
  echom 'HoverCallback'
  echom a:response
endfunction

function DidOpen() abort
  let l:didOpen = {
    \'method':'textDocument/didOpen',
    \'params':{
      \'textDocument': {
        \'uri':  'file:///home/alba/proyects/lsp/typescript/src/main.ts',
        \'languageId': 'typescript', 
        \'version': 1,
        \'text': Get_Lines(),
      \},
    \},
  \}
  call ch_sendexpr(b:channel,l:didOpen)
endfunction

"call LspStart()
"call LspInit()
"call DidOpen()
"call Hover()
"call LspStop()
"

function! Get_Lines() abort
    let l:lines = getbufline(2, 1, '$')
    return join(l:lines, "\n")
endfunction
