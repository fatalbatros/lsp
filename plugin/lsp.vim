vim9script
import autoload "lsp.vim" as lsp

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

# Entry points
command! LspStart call lsp.LspStart()
command! LspClose call lsp.LspClose()
command! LspClean call lsp.LspClean()
