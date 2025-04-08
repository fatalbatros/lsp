vim9script
import "./diagnostic.vim" as diag
import "./setup.vim" as setup

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

if !has_key(g:lsp, 'rust')
  g:lsp['rust'] = {
    'cmd': ['rust-analyzer'],
  }
endif

var opt = {
#   'err_cb': 'LspStderr',
  'exit_cb': 'LspExit',
  'out_cb': 'LspStdout',
  'noblock': 1,
  'in_mode': 'lsp',
  'out_mode': 'lsp',
}

var capabilities = {
  'workspace': {
    'workspaceFolders': v:false,
    'configuration': v:false,
    'symbol': {'dynamicRegistration': v:false},
    'applyEdit': v:false
  },
  'textDocument': {
    'hover': {
      'dynamicRegistration': v:false,
      'contentFormat': ["plaintext"]
    },
    'completion': {
      'dynamicRegistration': v:false,
      'completionItem': {
        'snippetSupport': v:false,
        'documentationFormat': ["plaintext"],
        'preselectSupport': v:false
      },
      'insertReplaceSupport': v:false,
      'contextSupport': v:false,
    },
    'syncrhonization': {
      'dynamicRegistration': v:false,
      'willSaveWaitUntil': v:false,
      'willSave': v:false,
      'didSave': v:true
    },
    'publishDiagnostics': {
      'relatedInformation': v:true,
      'versionSuport': v:false,
      'dynamicRegistration': v:false,
      'dataSupport': v:false,
      'codeDescriptionSupport': v:false,
    },
  },
}


def g:LspStart()
  # start and restart the server
  if !has_key(g:lsp, &filetype)
    echohl ErrorMsg
    echo 'Lsp for ' .. &filetype .. ' not set'
    echohl Normal
    return
  elseif !has_key(g:lsp[&filetype], 'cmd')
    echohl ErrorMsg
    echo 'Lsp start command for ' .. &filetype .. ' is not defined'
    echohl Normal
    return
  elseif has_key(g:lsp[&filetype], 'job_id') 
    if ch_status(g:lsp[&filetype]['job_id']) == 'open'
      echohl Added
      echo 'Lsp for ' .. &filetype .. ' is already running'
      echohl Normal
      return
    else
      job_stop(g:lsp[&filetype]['job_id'])
    endif
  endif

  var cmd = g:lsp[&filetype]['cmd']
  var job_id = job_start(cmd, opt)
  g:lsp[&filetype]['job_id'] = job_id
  g:lsp[&filetype]['channel'] = job_getchannel(job_id)
  g:synchronized = {}
  g:diagnostics = {}
  g:show_diagnostic = v:true
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
      diag.PublishDiagnosticsCB(data['params'])
      return
    endif
  endif
  echom data
enddef

# On error some servers (cairo) send a response that is no encoded in json
# format. The channel set to "lsp" fails to decode it. An this throw an error.
# At the moment Im not seting a callback for errors.
def LspStderr(channel: channel, data: dict<any>)
  echom 'Error'
  echom data
enddef

def LspExit(job_id: job, exit_code: number)
  var buf = bufnr('%')
  bufdo call prop_clear(1, line('$'))
  execute 'buffer ' .. buf
  augroup LspBuferAu
    autocmd! * <buffer>
  augroup END
  echohl ErrorMsg | echom 'F for the LSP' | echohl Normal
  # TODO: This removes all autocomans and all diagnostics for all buffers. Change this to bufer specifics to the lsp  
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
  ch_sendexpr(g:lsp[&filetype]['channel'], request, {'callback': 's:InitCallback'})
enddef

def InitCallback(channel: channel, response: dict<any>)
  g:init_response = response
  if has_key(response, 'result') && has_key(response['result'], 'capabilities')
    g:capabilities = response['result']['capabilities']
    ch_sendexpr(channel, {'method': 'initialized', 'params': {}})
    setup.EnsureStart()
  endif
enddef

def g:LspStatus()
  for i in keys(g:lsp)
    echon i .. ' : '
    PrintStatus(i)
    echo '' 
  endfor
enddef

def PrintStatus(filetype: string)
  var server = g:lsp[filetype]
  if !has_key(server, 'job_id')
    echon 'NOT STARTED "' .. join(server['cmd']) .. '"'
    return
  endif
  var info = job_info(server['job_id'])
  if info['status'] == 'run'
    echohl Added | echon 'RUNNING ' | echohl Normal
    echon info['process']
  elseif info['status'] == 'fail'
    echohl ErrorMsg | echon 'FAILED' | echohl Normal
  elseif info['status'] == 'dead' 
    echohl ErrorMsg | echon 'STOPED ' | echohl Normal
  endif
enddef

