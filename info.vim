vim9script

export def g:LspInfo()
  echo 'The configuration is stored in the variable g:lsp under the filetype key.To add a lsp server for a specific  filetype just add a entry to the g:lsp[filetype] dict with the command to start the server. For example:'
  echo "   let g:lsp['rust']['cmd'] = ['rust-analyzer']" 
  echo '    '
  echo 'When calling LspStart, vim will try to spawn a child process with the command stored in the "cmd" key for the current filetype. Then all files opened files that match the filetype are sent to the server to synchronize them. An autocommand is set to synchronize newlly opened files that match the filetype. Sync files are stored in the g:synchronize dictionary under the URI key:'

  echo "   g:synchronized = {file:///home/name/file1.rs: {'version':32, 'bufer':1, 'filetype':'rust'},"
  echo "                     file:///home/name/file2.rs: {'version':1, 'bufer':2, 'filetype':'rust'}}"
  echo '    '
  echo "Some vim actions trigger a resync atempt calling to the ForceSync() function through autocommands.  To determine if a resynchronization is needed the vim b:changedtick variable is ussed. For each buffer it previous b:changedtic is stored in the b:sync_changedtick. When they are not equal, the new version of the file is sent to the server."
  echo 'ForceSync() is triggered on:'
  echo '   -bufenter'
  echo '   -bufwritepost'
  echo '   -insertleave'
  echo '   -textchanged'
enddef

