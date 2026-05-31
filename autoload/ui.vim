vim9script

export def PopupOpts(): dict<any>
    return {
        border: [1, 1, 1, 1],
        highlight: 'Normal',
        borderhighlight: ['LineNr'],
        borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
    }
enddef
