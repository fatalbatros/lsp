let s:cmd = ['typescript-language-server','--stdio']
let s:opt = {
    \ 'exit_cb': 'LspExit',
    \ 'out_cb': 'LspStdout',
    \ 'err_cb': 'LspStderr',
    \ 'noblock': 1,
    \ 'mode': 'lsp',
  \}

function LspStart()
  let b:job_id = job_start(s:cmd,s:opt)
  let b:info = job_info(b:job_id)
  let b:channel = job_getchannel(b:job_id)
endfunction

function LspStop()
  call job_stop(b:job_id)
  echo "done"
endfunction


function! LspExit(job_id, exit_code)
  echo 'Exit'
  echo 'LSP exited with status: ' . a:exit_code
endfunction


call LspStart()
echo b:info
call LspStop()

