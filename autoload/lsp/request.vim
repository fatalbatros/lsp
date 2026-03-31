vim9script

export def Send(filetype: string, request: dict<any>, ops: dict<any> = {}): any
    if !has_key(g:lsp, filetype) | return v:null | endif

    const channel = get(g:lsp[filetype], 'channel', v:null)    
    if channel == v:null | return v:null | endif
    if ch_status(channel) != 'open' | return v:null | endif

    return ch_sendexpr(channel, request, ops)
enddef
