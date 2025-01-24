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

"keymaps 
function! s:Maps() abort
  nnoremap <silent><buffer> K :call Hover()<CR>
  nnoremap <silent><buffer> gd :call Definition()<CR>
  nnoremap <silent><buffer> <space>s :call ForceSync()<CR>
  nnoremap <silent><buffer> ]d :call NextDiagnostic()<CR>
  nnoremap <silent><buffer> [d :call PreviousDiagnostic()<CR>
endfunction

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

function! s:LspStdout(channel, data) abort
  echom 'LspStdout'
"  echom a:data
  if has_key(a:data,'method')
    if a:data['method'] == 'textDocument/publishDiagnostics'
      if !exists("g:diagnostics") 
        let g:diagnostics ={}
      endif
      let l:temp = a:data['params'] 
      let g:diagnostics[l:temp['uri']] = l:temp['diagnostics']
      call ParseDiagnostics()
    endif
  endif
endfunction


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

  execute 'au filetype ' . &filetype . ' call SetupBuffer()'
  bufdo call s:EnsureStart(&filetype)
endfunction


function s:EnsureStart(type)
  echom 'Ensure'
  let l:buf = bufnr('%')
  bufdo  if &filetype == a:type | call SetupBuffer() | endif 
  execute 'buffer ' . l:buf
endfunction

function! SetupBuffer() abort
  augroup LspBuferAu
    autocmd! * <buffer>
    au bufenter <buffer> call ParseDiagnostics()  
    au bufdelete <buffer> call DidClose(expand('<afile>:p')) 
    au bufenter <buffer> call ForceSync()  
  augroup END
  call ForceSync()
  call  s:Maps()
endfunction


function! ForceSync() abort
"TODO: revisar b:changedtick
  let l:uri = 'file://' . expand("%:p")
  if !has_key(g:lsp[&filetype]['files'], l:uri)
    let b:sync_changedtick = b:changedtick
    call DidOpen(l:uri)
  else
    if b:sync_changedtick != b:changedtick
      let b:sync_changedtick = b:changedtick
      call DidChange(l:uri)
    endif
  endif
endfunction

function! DidOpen(uri) abort
  let l:didOpen = {
    \'method':'textDocument/didOpen',
    \'params':{
      \'textDocument': {
        \'uri': a:uri,
        \'languageId': &filetype, 
        \'version': 1,
        \'text': s:get_lines(),
      \},
    \},
  \}
  call ch_sendexpr(g:lsp[&filetype]['channel'],l:didOpen)
  let g:lsp[&filetype]['files'][a:uri] = {'bufer': bufnr(), 'version': 1}
endfunction


function! DidClose(file) abort
  let l:uri = 'file://' . a:file
  let l:didClose = {
    \'method':'textDocument/didClose',
    \'params':{
      \'textDocument': {
        \'uri': l:uri,
      \},
    \},
  \}
  call ch_sendexpr(g:lsp[&filetype]['channel'], l:didClose)
  unlet g:lsp[&filetype]['files'][l:uri]
  if exists("g:diagnostics")
    if has_key(g:diagnostics, l:uri) | unlet g:diagnostics[l:uri] | endif
  endif
endfunction

function! s:get_lines() abort
  let l:lines = getbufline(bufnr(), 1, '$')
  return join(l:lines, "\n")
endfunction

function! DidChange(uri) abort
  let l:version = g:lsp[&filetype]['files'][a:uri]['version']
  let g:lsp[&filetype]['files'][a:uri]['version'] += 1
  let l:didChange = {
    \'method':'textDocument/didChange',
    \'params':{
      \'textDocument': {
        \'uri': a:uri,
        \'languageId': &filetype, 
        \'version': l:version + 1,
      \},
      \'contentChanges': [{'text': s:get_lines() }],
    \},
  \}
  call ch_sendexpr(g:lsp[&filetype]['channel'],l:didChange)
endfunction
