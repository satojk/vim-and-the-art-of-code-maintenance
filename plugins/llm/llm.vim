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
    execute "split " . s:excerpt_file
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
    let l:rewrite_end = strridx(l:response, "</rewrite>")

    if l:rewrite_start != -1 && l:rewrite_end != -1
        let l:rewrite = l:response[l:rewrite_start+9 : l:rewrite_end-1]

        " Update the excerpt buffer
        call writefile(split(l:rewrite, "\n"), s:excerpt_file)
        execute "buffer " . s:excerpt_bufnr
        edit!

        " Generate diff
        call s:GenerateDiff()

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
                 \ "include the rewritten version of the **entire file** within <rewrite> tags. " .
                 \ "This is important because the entire file will be replaced by the version you rewrote."

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

function! s:GenerateDiff()
    let l:temp_original = tempname()
    let l:temp_rewrite = tempname()

    " Save original content (entire file)
    let l:original_content = join(getbufline(bufnr(s:original_file), 1, '$'), "\n")
    call writefile(split(l:original_content, "\n"), l:temp_original)

    " Save rewritten content (entire file)
    let l:rewrite_content = join(getbufline(s:excerpt_bufnr, 1, '$'), "\n")
    call writefile(split(l:rewrite_content, "\n"), l:temp_rewrite)

    " Generate diff
    let l:diff_command = 'diff -u ' . shellescape(l:temp_original) . ' ' . shellescape(l:temp_rewrite) . ' > ' . shellescape(s:excerpt_diff_file)
    call system(l:diff_command)

    " Clean up temporary files
    call delete(l:temp_original)
    call delete(l:temp_rewrite)
endfunction

function! s:ApplyChanges()
    " Read the content from the excerpt file
    let l:new_content = readfile(s:excerpt_file)

    " Switch to the original file buffer
    execute "buffer " . bufnr(s:original_file)

    " Save the current view
    let l:view = winsaveview()

    " Replace the entire content of the original file
    silent! execute "undojoin | keepjumps keeppatterns %delete_"
    call append(0, l:new_content)
    if getline('$') == ''
        silent! undojoin | $delete_
    endif

    " Update the end line number
    let s:end_line = line('$')

    " Restore the view
    call winrestview(l:view)

    " Ensure the cursor is on a valid line
    if line('.') > line('$')
        normal! G
    endif

    " Ensure folds are opened as they were before
    normal! zv

    echo "Changes applied successfully."
endfunction

function! s:ToggleExcerptDiff()
    " Save the current window number
    let l:current_win = winnr()

    " Find the window with the excerpt or diff buffer
    let l:excerpt_win = bufwinnr(s:excerpt_bufnr)
    let l:diff_win = bufwinnr(s:excerpt_diff_file)
    let l:target_win = l:excerpt_win != -1 ? l:excerpt_win : l:diff_win

    " If neither window is found, do nothing
    if l:target_win == -1
        echo "Excerpt or diff window not found."
        return
    endif

    " Move to the target window
    execute l:target_win . "wincmd w"

    " Toggle between excerpt and diff
    if &filetype == 'diff'
        execute "buffer " . s:excerpt_bufnr
        execute "set filetype=" . &filetype
    else
        call s:GenerateDiff()
        execute "edit " . s:excerpt_diff_file
        setlocal filetype=diff
    endif

    " Return to the original window
    execute l:current_win . "wincmd w"
endfunction

command! -range Llm <line1>,<line2>call <SID>CopyToTmp()
command! Ask call <SID>GetCompletion()
command! Apply call <SID>ApplyChanges()
command! Ted call <SID>ToggleExcerptDiff()
command! GenDiff call <SID>GenerateDiff()
