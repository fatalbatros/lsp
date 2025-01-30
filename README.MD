Im writing a lsp client in vim. The overall roadmap will be: hover, go to definition, diagnostics, completions.

At the moment I will be testing with typescript lsp. The to "configure" a server just add to the g:lsp dictionary a new key "filetype": {cmd: 'command to run the server'}

To "load" the client just source the source.vim file and call LspStart() from a file. 


DONE: 
- Hover: call Hover() or use K
- Pupup: The popupwindows is very basic and I have no plans to bloat it.
- Definition: call Definition() or use gd.
- Diagnostics: The files are sync when opened. Use <space>w or :call ForceSync() to resync them.
  At the moment I do not know when should be optimal to sync the files. This will change in the future.
  The maps ]d and [d can be used to navigate throught diferent diagnostics.
- Completion: The omnifunc (^X ^O) is set to use completion of the lsp. There is an overhead of 
  showing the extra info en the popup menu of sync the file each time a new item is selected

TODO:
- Sync: At the moment the open files sync between server and clients is very sub-optimal. 
  Each time you trigger a Hover if the file is flag as modified by vim, the client sends
  and didClose request and then a didOpen request with all the content of the file to the
  server. I have to update that to use the didChange request. For that I have to write functions
  to compute the diferene between the current version of the file and a previous version to
  send only the diff.

- Sync: I dont know if executing a function to compute the changes in a file will will be faster than
  sending the fille. I suspect that for small files there will be no diference. 

- Position: The TextDocumentPositionsParams.position is {line, character}. I am ussing the vim  getpos()
  function. I dont know if it is a diference between the character number and the column number (I think 
  tabs are a single character that spans severals columns). I am using the vim  setcursorcharpos() function
  to set the position after go to definition, there also existe the vim cursor() function. The diference
  between them made me think that thece could be a problem.

- Competions: At the moment, each time a new item is selected a new ForceSync() has to be triger in order
  to get the hover info to display in the popup. There is a request completionItem/resolve that should
  give extra information (if the server implement it) this would be optimal.

- Load: I have to research the optimal way of autoload the client. At the moment I have an autocmd
  that sources the source.vim file while filetype is triger. I like the idea of only load the cliente
  when you open a filetype that has a server configured. 

Tasks:
- vim9 : ForceSync should  not handle the version of the file. 

Next Planed Step:
- I need to handle properlly the initialization request/options.

