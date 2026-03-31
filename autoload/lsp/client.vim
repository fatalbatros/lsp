vim9script
import autoload "diagnostic.vim" as diag
import autoload "utils.vim" as utils
import autoload "setup.vim" as setup
import autoload "lsp/request.vim" as Request

# Configuration 
if !exists("g:lsp")
    g:lsp = {}
    g:lsp['cairo'] = {
        'cmd': ['scarb', 'cairo-language-server', '/C', '--node-ipc'],
        'root_markers': [
            {type: 'file', name: 'Scarb.toml', priority: 1},
            {type: 'dir', name: '.git', priority: 10}, 
        ]
    }
    g:lsp['typescript'] = {
        'cmd': ['typescript-language-server', '--stdio'],
        'root_markers': [
            {type: 'file', name: 'tsconfig.json', priority: 1},
            {type: 'file', name: 'jsconfig.json', priority: 3},
            {type: 'file', name: 'package.json', priority: 4},
            {type: 'dir',  name: '.git',          priority: 10},
        ]
    }
endif

var opt = {
#   'err_cb': 'OnStderr',
  'exit_cb': 'OnStdExit',
  'out_cb': 'OnStdout',
  'noblock': 1,
  'in_mode': 'lsp',
  'out_mode': 'lsp',
}

def OnStderr(channel: channel, data: dict<any>)
  echom data
enddef


def OnStdout(channel: channel, data: dict<any>)
  if has_key(data, 'method')
    if data['method'] == 'textDocument/publishDiagnostics'
      diag.PublishDiagnosticsCB(data['params'])
      return
    endif
  endif
enddef


def OnStdExit(job_id: job, exit_code: number)
    var filetype = ''

    for [key, item] in items(g:lsp)
        var job_stored = get(item, 'job_id', '')

        job_id != job_stored
            continue
        endif

        filetype = key
        break
    endfor

    if filetype == '' | return | endif

    setup.ClearFiletype(filetype)

    unlet g:lsp[filetype]['job_id']
    unlet g:lsp[filetype]['channel']
    unlet g:lsp[filetype]['initialized']
enddef

var capabilities = {
    'workspace': {
        'applyEdit': v:false,
        'workspaceFolders': v:false,
        'configuration': v:false,
    },
    'textDocument': {
        'synchronization': {
            'didSave': v:true,
            'willSave': v:false,
            'willSaveWaitUntil': v:false,
        },
        'hover': { 'contentFormat': ['plaintext'] },
        'definition': {},
        'rename': { 'prepareSupport': v:false },
        'codeAction': { 'dynamicRegistration': v:false },
        'completion': {
            'completionItem': {
                'snippetSupport': v:false,
                'documentationFormat': ['plaintext'],
                'resolveSupport': { 'properties': ['documentation', 'detail'] }
            }
        },
        'publishDiagnostics': { 'relatedInformation': v:true }
    },
    'window': { 'workDoneProgress': v:false },
    'general': { 'positionEncodings': ['utf-16'] }
}

export def Start()
    const filetype = &filetype
    # start and restart the server
    if !has_key(g:lsp, filetype)
        utils.EchoError('Lsp for ' .. filetype .. ' not set')
        return
    endif

    if !has_key(g:lsp[filetype], 'cmd')
        utils.EchoError('Lsp start command for ' .. filetype .. ' is not defined')
        return
    endif

    if has_key(g:lsp[filetype], 'job_id') 
        if ch_status(g:lsp[filetype]['job_id']) == 'open'
            utils.EchoOk('Lsp for ' .. filetype .. ' is already running')
            return
        endif
        job_stop(g:lsp[filetype]['job_id'])
    endif

    var cmd = g:lsp[filetype]['cmd']
    var job_id = job_start(cmd, opt)
    g:lsp[filetype]['job_id'] = job_id
    g:lsp[filetype]['channel'] = job_getchannel(job_id)
    g:lsp[filetype]['initialized'] = v:false

    if !exists('g:diagnostics')
        g:diagnostics = {}
    endif
    if !exists('g:lsp_synchronized')
        g:lsp_synchronized = {}
    endif
    g:show_diagnostic = v:true
    LspInit(filetype)
enddef


def LspInit(filetype: string)
    const rootPath = utils.FindRootDir(expand("%:p:h"), filetype)
    echom 'initialize in ' .. rootPath
    var request = {
       'method': 'initialize',
       'params': {
            'processId': getpid(),
            'clientInfo': {'name': 'lsp-joel', 'version': '0'},
            'capabilities': capabilities,
            'rootPath': rootPath,
            'rootURI': utils.PathToUri(rootPath),
            'trace': 'off',
        },
    }
    g:lsp_request = request
    g:lsp[filetype]['root'] = rootPath
    Request.Send(filetype, request, {'callback': (ch, res) => InitCallback(ch, res, filetype)})
enddef

# TODO: capabilities are overwriten by other servers
def InitCallback(channel: channel, response: dict<any>, filetype: string)
    g:lsp_response = response
    if has_key(response, 'result') && has_key(response['result'], 'capabilities')
        g:capabilities = response['result']['capabilities']
        Request.Send(filetype, {'method': 'initialized', 'params': {}})
        g:lsp[filetype]['initialized'] = v:true
        utils.EchoOk('lsp initialized for ' .. filetype)
        setup.SetupFiletype(filetype)
        return 
    endif
    utils.EchoError('lsp initialization failed for ' .. filetype)
enddef


export def Stop()
  if has_key(g:lsp, &filetype) && has_key(g:lsp[&filetype], 'job_id')
    job_stop(g:lsp[&filetype]['job_id'])
  else
    utils.EchoError('Lsp server for ' .. &filetype .. ' not found')
  endif
enddef
