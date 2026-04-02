vim9script 

# The result is of type (Command | CodeAction)[]
#
# export interface CodeAction {
#     title: string;
#     kind?: CodeActionKind;
#     diagnostics?: Diagnostic[];
#     isPreferred?: boolean;
#     disabled?: { reason: string; };
#     edit?: WorkspaceEdit;
#     command?: Command;
#     data?: LSPAny;
# }
#
# With WorkspaceEdit 
# export interface WorkspaceEdit {
#     changes?: { [uri: DocumentUri]: TextEdit[]; };
# 
#     documentChanges?: (
#         TextDocumentEdit[] |
#         (TextDocumentEdit | CreateFile | RenameFile | DeleteFile)[]
#     );
# 
#     changeAnnotations?: {
#     };
# }
#
# And TextDocumentEdit 
#
# export interface TextDocumentEdit {
#         textDocument: OptionalVersionedTextDocumentIdentifier;
# 
#         edits: (TextEdit | AnnotatedTextEdit)[];
# }
#
# Te objective is Normalize all of this in 
#   {
#       'title':string,
#       'kind':string,
#       'changes': {['uri': strin]: TextEdit[]}
#   }

export def NormalizeCodeActionResult(result: list<dict<any>>): list<dict<any>>
    var list = []
    for codeAction in result
        echom "CA codeAction"
        echom codeAction
        
        var changes: dict<any> = {}
        var title = get(codeAction, 'title', v:null)
        if title == v:null | continue | endif

        var kind = get(codeAction, 'kind', 'unknown')
        
        var edit = get(codeAction, 'edit', v:null)
        if edit == v:null | continue |endif
        
        if has_key(edit, 'changes')
            changes = edit.changes
            add(list, {'title': title, 'kind': kind, 'changes': changes})
            continue
        endif
        
        var documentChanges = get(edit, 'documentChanges', v:null)
        if documentChanges == v:null | continue | endif
    
        for  textDocumentEdit in documentChanges
            if !has_key(textDocumentEdit, 'textDocument') | continue | endif

            var uri = get(textDocumentEdit.textDocument, 'uri', v:null)
            if uri == v:null | continue | endif

            var edits = textDocumentEdit.edits
            changes[uri] = edits

            add(list, {'title': title, 'kind': kind, 'changes': changes})
        endfor
    endfor

    return list
enddef
