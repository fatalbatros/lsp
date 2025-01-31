vim9script
import "./diagnostic.vim" as diag

# Configuration 
if !exists("g:lsp")
  g:lsp = {}
endif

if !has_key(g:lsp, 'typescript')
  g:lsp['typescript'] = {
    'cmd': ['typescript-language-server', '--stdio'],
  }
endif

if !has_key(g:lsp, 'cairo')
  g:lsp['cairo'] = {
    'cmd': ['scarb', 'cairo-language-server', '/C', '--node-ipc'],
  }
endif

var opt = {
  'exit_cb': 'LspExit',
  'out_cb': 'LspStdout',
  'err_cb': 'LspStderr',
  'noblock': 1,
  'in_mode': 'lsp',
  'out_mode': 'lsp',
}

var capabilities = {
  'workspace': {},
  'textDocument': {
    'hover': {
      'dynamicRegistration': v:false,
      'contentFormat': ['plaintext', 'markdown']
    },
    'syncrhonization': {
      'dynamicRegistration': v:false,
      'willSaveWaitUntil': v:false,
      'willSave': v:false,
      'didSave': v:true
    },
    'publishDiagnostics': {
      'relatedInformation': v:true,
      'versionSuport': v:true,
      'dynamicRegistration': v:false,
    },
  },
}


def g:LspStart()
  # start and restart the server
  if !has_key(g:lsp, &filetype)
    echoerr 'Lsp for ' .. &filetype .. ' not set'
    return
  elseif !has_key(g:lsp[&filetype], 'cmd')
    echoerr 'Lsp start command not defined for ' .. &filetype
    return
  elseif has_key(g:lsp[&filetype], 'job_id') 
    if ch_status(g:lsp[&filetype]['job_id']) == 'open'
      echoerr 'Lsp for ' .. &filetype .. ' is running'
      return
    else
      job_stop(g:lsp[&filetype]['job_id'])
    endif
  endif

  var cmd = g:lsp[&filetype]['cmd']
  var job_id = job_start(cmd, opt)
  g:lsp[&filetype]['job_id'] = job_id
  g:lsp[&filetype]['channel'] = job_getchannel(job_id)
  g:lsp[&filetype]['files'] = {}
  g:diagnostics = {}
  LspInit()
enddef

def g:LspStop()
  if has_key(g:lsp, &filetype) && has_key(g:lsp[&filetype], 'job_id')
    job_stop(g:lsp[&filetype]['job_id'])
    unlet g:lsp[&filetype]['job_id']
    unlet g:lsp[&filetype]['channel']
  else
    echom 'Lsp server for ' .. &filetype .. ' not found'
  endif
enddef

def LspStdout(channel: channel, data: dict<any>)
  if has_key(data, 'method')
    if data['method'] == 'textDocument/publishDiagnostics'
      PublishDiagnosticsCB(data['params'])
      return
    endif
  endif
  echom data
enddef

def PublishDiagnosticsCB(params: dict<any>)
  var uri = params['uri']
  if bufexists(strpart(uri, 7))
    g:diagnostics[uri] = params['diagnostics']
    diag.ParseDiagnostics()
  endif
enddef

def LspStderr(channel: channel, data: dict<any>)
  echom 'Error'
  echom data
enddef

def LspExit(job_id: job, exit_code: number)
  echom 'LSP exited with status: ' .. exit_code
enddef

def LspInit()
  echom 'initialize'
  var request = {
       'method': 'initialize',
       'params': {
         'processId': getpid(),
         'clientInfo': {'name': 'lsp-joel', 'version': '0'},
         'capabilities': capabilities,
         'rootPath': expand("%:p:h"),
         'rootURI': 'file://' .. expand("%:p:h") .. '/',
         'trace': 'off',
       },
  }
  ch_sendexpr(g:lsp[&filetype]['channel'], request, {'callback': 'InitCallback'})
enddef

def InitCallback(channel: channel, response: dict<any>)
  g:init_response = response
  if has_key(response, 'result') && has_key(response['result'], 'capabilities')
    g:capabilities = response['result']['capabilities']

    ch_sendexpr(channel, {'method': 'initialized', 'params': {}})
    execute 'au filetype ' .. &filetype .. ' call SetupBuffer("' .. &filetype .. '")'
    var filetype = &filetype
    g:EnsureStart(filetype)
  endif
enddef


