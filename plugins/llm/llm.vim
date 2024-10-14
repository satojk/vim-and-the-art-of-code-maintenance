" File: $VIM_LOCAL_PLUGINS_DIR/llm/plugin/llm.vim

if exists("g:loaded_llm")
    finish
endif
let g:loaded_llm = 1

let s:excerpt_file = expand('~/vim_llm_excerpt_tmp')
let s:excerpt_diff_file = expand('~/vim_llm_excerpt_diff_tmp')
let s:chat_file = expand('~/vim_llm_chat_tmp')
let s:original_file = ''
let s:start_line = 0
let s:end_line = 0
let s:excerpt_bufnr = -1
let s:chat_bufnr = -1

function! s:CopyToTmp() range
    let s:original_file = expand('%:p')
    let s:start_line = a:firstline
    let s:end_line = a:lastline
    let l:selected_content = join(getline(a:firstline, a:lastline), "\n")
    let l:original_filetype = &filetype

    " Prepare files
    call writefile(split(l:selected_content, "\n"), s:excerpt_file)
    call writefile([], s:chat_file)

    " Create the splits
    execute "vsplit " . s:chat_file
    let s:chat_bufnr = bufnr('%')
    execute "20split " . s:excerpt_file
    let s:excerpt_bufnr = bufnr('%')
    execute "set filetype=" . l:original_filetype
    normal! zR

    " Move cursor to the chat buffer and enter insert mode
    wincmd j
    startinsert
endfunction

function! s:GetCompletion()
    execute "w"
    let l:full_content = join(getbufline(bufnr(s:original_file), 1, '$'), "\n")
    let l:selected_content = join(getbufline(s:excerpt_bufnr, 1, '$'), "\n")

    let l:user_request = join(getbufline(s:chat_bufnr, 1, '$'), "\n")

    let l:response = s:GetAnalysisFromClaude(l:full_content, l:selected_content, l:user_request)

    " Check for rewrite tags
    let l:rewrite_start = stridx(l:response, "<rewrite>")
    let l:rewrite_end = stridx(l:response, "</rewrite>")

    if l:rewrite_start != -1 && l:rewrite_end != -1
        let l:rewrite = l:response[l:rewrite_start+9 : l:rewrite_end-1]

        " Update the excerpt buffer
        call writefile(split(l:rewrite, "\n"), s:excerpt_file)
        execute "buffer " . s:excerpt_bufnr
        edit!

        " Generate diff
        let l:temp_original = tempname()
        let l:temp_rewrite = tempname()

        " Save original content
        let l:original_content = join(getbufline(bufnr(s:original_file), s:start_line, s:end_line), "\n")
        call writefile(split(l:original_content, "\n"), l:temp_original)

        " Save rewritten content
        call writefile(split(l:rewrite, "\n"), l:temp_rewrite)

        " Generate diff
        let l:diff_command = 'diff -u ' . shellescape(l:temp_original) . ' ' . shellescape(l:temp_rewrite) . ' > ' . shellescape(s:excerpt_diff_file)
        call system(l:diff_command)

        " Clean up temporary files
        call delete(l:temp_original)
        call delete(l:temp_rewrite)

        " Remove the rewrite tags from the response
        let l:response = l:response[:l:rewrite_start-1] . l:response[l:rewrite_end+10:]
    endif

    " Update the request/response buffer
    call writefile(split(l:response, "\n"), s:chat_file)
    execute "buffer " . s:chat_bufnr
    edit!
    " go to the split above
    wincmd k
    execute "edit " . s:excerpt_diff_file
    setlocal filetype=diff
endfunction

function! s:GetAnalysisFromClaude(full_text, selected_text, user_request)
    let l:api_key = $ANTHROPIC_API_KEY
    if empty(l:api_key)
        return "Error: ANTHROPIC_API_KEY not set"
    endif

    let l:prompt = "Hello! I'm writing some code. Here's the full file that I have open:\n\n" . a:full_text .
                 \ "\n\nNow, focus on this selected section:\n\n" . a:selected_text .
                 \ "\n\nI have the following request about the selected section:\n" . a:user_request .
                 \ "\n\nPlease provide a concise response. If my request involves modifying the code, " .
                 \ "include only the rewritten version of the selected section within <rewrite> tags. " .
                 \ "Do not include any code outside the selection in your rewrite. " .
                 \ "Be aware that the <rewrite> content will directly replace the selected section."

    let l:json_data = json_encode({
        \ "model": "claude-3-5-sonnet-20240620",
        \ "max_tokens": 4000,
        \ "messages": [
        \   {"role": "user", "content": l:prompt}
        \ ]
    \ })

    let l:command = 'curl -s -H "x-api-key: ' . l:api_key . '" ' .
                  \ '-H "Content-Type: application/json" ' .
                  \ '-H "anthropic-version: 2023-06-01" ' .
                  \ '-d ' . shellescape(l:json_data) . ' ' .
                  \ 'https://api.anthropic.com/v1/messages'

    let l:response = system(l:command)
    let l:response_json = json_decode(l:response)

    if has_key(l:response_json, 'content') && len(l:response_json.content) > 0
        return l:response_json.content[0].text
    else
        return "Error: Unable to get analysis from Claude API"
    endif
endfunction

function! s:ApplyChanges()
    let l:new_lines = readfile(s:excerpt_file)

    " Save the current view
    let l:view = winsaveview()

    " Apply the changes
    silent! execute "keepjumps keeppatterns buffer " . bufnr(s:original_file)
    silent! execute "keepjumps keeppatterns " . s:start_line . "," . s:end_line . "delete"
    silent! call append(s:start_line - 1, l:new_lines)

    " Update the end line number
    let s:end_line = s:start_line + len(l:new_lines) - 1

    " Restore the view
    call winrestview(l:view)

    " Adjust cursor position if it's after the changed section
    if line('.') > s:end_line
        let l:offset = len(l:new_lines) - (s:end_line - s:start_line + 1)
        execute "normal! " . l:offset . "j"
    endif

    " Ensure folds are opened as they were before
    normal! zv

    echo "Changes applied to original file."
endfunction

command! -range Llm <line1>,<line2>call <SID>CopyToTmp()
command! Ask call <SID>GetCompletion()
command! Apply call <SID>ApplyChanges()
