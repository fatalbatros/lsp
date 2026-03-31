vim9script

import autoload "lsp/sync.vim" as sync
import autoload "utils.vim" as utils
import autoload "lsp/request.vim" as Request

var last_hover: list<string> = []
var hover_id = -1

def OnHoverClose(id: number, _: any) 
    hover_id = -1
enddef

const popup_options = {
    'border': [1, 1, 1, 1],
    'highlight': 'Normal',
    'borderhighlight': ['LineNr'],
     borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'], 
    'moved': 'word',
    'callback': function('OnHoverClose')
}

export def HoverOrPreview() 
    if hover_id != -1 && !empty(popup_getpos(hover_id))
        popup_close(hover_id)
        HoverPreview()
    else
        Hover()
    endif 
enddef

def Hover()
    sync.ForceSync()
    const cursor = getpos('.')
    const uri = utils.GetCurrentUri()
    var request = {
        'method': 'textDocument/hover',
        'params': {
            'textDocument': {'uri': uri },
            'position': {
                'line': cursor[1] - 1,
                'character': cursor[2] - 1,
            }
        }
    }
    g:lsp_request = request

    Request.Send(&filetype, request, {'callback': (ch, res) => HoverCallback(ch, res) })
enddef

def HoverCallback(channel: channel, response: dict<any>)
    g:lsp_response = response
    if response['result'] == v:null | return | endif
    if response['result']['contents'] == v:null | return | endif

    const lines = Parse_hover_response(response.result.contents)
    if empty(lines) | return | endif
    last_hover = lines

    if hover_id != -1 | popup_close(hover_id) | endif
    const id = popup_create(lines, popup_options)
    hover_id = id

    call win_execute(id, 'setlocal filetype=markdown')
    call win_execute(id, 'syntax match markdownError "\w\@<=\w\@="')
enddef


def Parse_hover_response(contents: any): list<string>
    var parsed: list<string> = []
    if type(contents) == type("")
        parsed = split(contents, '\r\n\|\r\|\n', v:true)

    elseif type(contents) == type({}) 
        if !has_key(contents, "value") | return [] | endif
        parsed =  split(contents.value, '\r\n\|\r\|\n', v:true)

    elseif type(contents) == type([])
        for c in contents 
            parsed += Parse_hover_response(c)
        endfor
    endif

    return parsed
enddef

export def HoverPreview() 
    if empty(last_hover) | return | endif
    vertical pedit preview
    wincmd P
    vertical resize 65
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted

    setlocal modifiable
    call setline(1, last_hover)
    setlocal nomodifiable

    setlocal filetype=markdown
    syntax match markdownError "\w\@<=\w\@="
enddef
