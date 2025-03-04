" File: $VIM_LOCAL_PLUGINS_DIR/llm/plugin/llm.vim

if exists("g:loaded_llm")
    finish
endif
let g:loaded_llm = 1

let s:excerpt_file = expand('~/vim_llm_excerpt_tmp')
let s:excerpt_diff_file = expand('~/vim_llm_excerpt_diff_tmp')
let s:chat_file = expand('~/vim_llm_chat_tmp')
let s:response_file = expand('~/vim_llm_response_tmp')
let s:original_file = ''
let s:start_line = 0
let s:end_line = 0
let s:excerpt_bufnr = -1
let s:chat_bufnr = -1
let s:response_bufnr = -1

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
    let l:has_changes = 0
    let l:original_lines = getbufline(bufnr(s:original_file), 1, '$')
    let l:modified_lines = copy(l:original_lines)

    " First, collect all rewrites
    let l:rewrites = []
    let l:response_copy = l:response
    let l:rewrite_start = stridx(l:response_copy, "<rewrite>")
    let l:rewrite_end = stridx(l:response_copy, "</rewrite>")

    while l:rewrite_start != -1 && l:rewrite_end != -1
        let l:has_changes = 1

        " Extract the rewrite section
        let l:rewrite_content = l:response_copy[l:rewrite_start+9 : l:rewrite_end-1]
        let l:rewrite_lines = split(l:rewrite_content, "\n")

        " First line should contain line number reference
        let l:line_ref = l:rewrite_lines[0]
        let l:line_start = 0
        let l:line_end = 0

        " Parse line numbers (format: "Lines X-Y:" or "Line X:")
        if l:line_ref =~# '^\s*Lines\s\+\d\+\s*\-\s*\d\+\s*:'
            let l:matches = matchlist(l:line_ref, 'Lines\s\+\(\d\+\)\s*\-\s*\(\d\+\)\s*:')
            let l:line_start = str2nr(l:matches[1])
            let l:line_end = str2nr(l:matches[2])
        elseif l:line_ref =~# '^\s*Line\s\+\d\+\s*:'
            let l:matches = matchlist(l:line_ref, 'Line\s\+\(\d\+\)\s*:')
            let l:line_start = str2nr(l:matches[1])
            let l:line_end = l:line_start
        endif

        " Only collect if we found valid line numbers
        if l:line_start > 0 && l:line_end >= l:line_start
            " Get the actual new content (skip the line reference)
            let l:new_content = l:rewrite_lines[1:]

            " Store this rewrite
            call add(l:rewrites, {'start': l:line_start, 'end': l:line_end, 'content': l:new_content})
        endif

        " Remove this rewrite section from the response
        let l:before_rewrite = l:response_copy[:l:rewrite_start-1]
        let l:after_rewrite = l:response_copy[l:rewrite_end+10:]
        let l:response_copy = l:before_rewrite . l:after_rewrite

        " Find next rewrite section
        let l:rewrite_start = stridx(l:response_copy, "<rewrite>")
        let l:rewrite_end = stridx(l:response_copy, "</rewrite>")
    endwhile

    " Sort rewrites by line number (ascending) to process from top to bottom
    call sort(l:rewrites, {a, b -> a.start - b.start})

    " Apply rewrites sequentially, adjusting line numbers for subsequent rewrites
    let l:line_offset = 0

    for l:rewrite in l:rewrites
        " Adjust line numbers based on previous changes
        let l:adjusted_start = l:rewrite.start + l:line_offset
        let l:adjusted_end = l:rewrite.end + l:line_offset

        " Calculate the line count difference this change will introduce
        let l:old_line_count = l:adjusted_end - l:adjusted_start + 1
        let l:new_line_count = len(l:rewrite.content)
        let l:diff = l:new_line_count - l:old_line_count

        " Apply this change
        let l:before = l:adjusted_start > 1 ? l:modified_lines[0:l:adjusted_start-2] : []
        let l:after = l:adjusted_end < len(l:modified_lines) ? l:modified_lines[l:adjusted_end:] : []
        let l:modified_lines = l:before + l:rewrite.content + l:after

        " Update line offset for subsequent changes
        let l:line_offset += l:diff
    endfor

    " Clean up the response by removing all rewrite sections
    let l:clean_response = l:response_copy

    if l:has_changes
        " Write the modified content to the excerpt file
        call writefile(l:modified_lines, s:excerpt_file)

        " Generate diff
        call s:GenerateDiff()

        " Update the excerpt buffer
        execute "buffer " . s:excerpt_bufnr
        edit!
    endif

    " Update the request/response buffer
    call writefile(split(l:clean_response, "\n"), s:chat_file)
    execute "buffer " . s:chat_bufnr
    edit!
    " go to the split above
    wincmd k
    execute "edit " . s:excerpt_diff_file
    setlocal filetype=diff
endfunction

function! s:AddLineNumbers(text, start_line)
    let l:lines = split(a:text, "\n")
    let l:numbered_lines = []
    let l:line_number = a:start_line

    for l:line in l:lines
        let l:numbered_line = printf("%4d | %s", l:line_number, l:line)
        call add(l:numbered_lines, l:numbered_line)
        let l:line_number += 1
    endfor

    return join(l:numbered_lines, "\n")
endfunction

function! s:GetAnalysisFromClaude(full_text, selected_text, user_request)
    let l:api_key = $ANTHROPIC_API_KEY
    if empty(l:api_key)
        return "Error: ANTHROPIC_API_KEY not set"
    endif

    " Add line numbers to both texts
    let l:numbered_full_text = s:AddLineNumbers(a:full_text, 1)
    let l:numbered_selected_text = s:AddLineNumbers(a:selected_text, s:start_line)

    let l:prompt = "Hello! I'm writing some code. Here's the full file that I have open (with line numbers):\n\n" . l:numbered_full_text .
                 \ "\n\nNow, consider this selected section (with line numbers):\n\n" . l:numbered_selected_text .
                 \ "\n\nI have the following request:\n" . a:user_request .
                 \ "\n\nPlease provide a concise response. If my request involves modifying the code, " .
                 \ "give a brief explanation of what is necessary to modify, and then include ONLY the ".
                 \ "modified sections within <rewrite> tags following these EXACT formatting rules: " .
                 \ "\n\n1. Start each modification with <rewrite>" .
                 \ "\n2. On the FIRST line inside the <rewrite> tag, specify the exact line numbers in ONE of these formats:" .
                 \ "\n   - For a single line: \"Line 42:\" (include the colon)" .
                 \ "\n   - For multiple consecutive lines: \"Lines 15-20:\" (include the colon)" .
                 \ "\n   - Use the actual line numbers visible at the beginning of each line in the code" .
                 \ "\n3. On the following lines, provide the COMPLETE new content for that section, including any unchanged lines" .
                 \ "\n4. When writing the new content, do NOT include the line numbers in your code" .
                 \ "\n5. End with </rewrite>" .
                 \ "\n\nExample format:" .
                 \ "\n<rewrite>" .
                 \ "\nLines 10-12:" .
                 \ "\nfunction newCode() {" .
                 \ "\n  return 'new implementation';" .
                 \ "\n}" .
                 \ "\n</rewrite>" .
                 \ "\n\nYou can include multiple <rewrite> sections if changes are needed in different parts of the file." .
                 \ "\nVery important:" .
                 \ "\n1. Make ALL necessary changes to fulfill the request completely. Do not merely describe changes - implement them in <rewrite> blocks" .
                 \ "\n2. If multiple changes are needed in different parts of the file, include all of them with separate <rewrite> sections" .
                 \ "\n3. NEVER include the line numbers in the actual code you provide - they are only for reference" .
                 \ "\n4. Always use the exact line numbers you see at the beginning of each line (e.g. '10 | function foo()' means this is line 10)" .
                 \ "\n5. The line numbers in your <rewrite> sections must exactly match the line numbers shown in the file"

    let l:json_data = json_encode({
        \ "model": "claude-3-7-sonnet-20250219",
        \ "max_tokens": 32000,
        \ "thinking": {
        \   "type": "enabled",
        \   "budget_tokens": 16000
        \ },
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
        " Check for thinking block and extract it
        let l:thinking = ""
        let l:text = ""

        for l:content in l:response_json.content
            if l:content.type == "thinking"
                let l:thinking = l:content.thinking
            elseif l:content.type == "text"
                let l:text = l:content.text
            endif
        endfor

        " Prepare a combined response for the response file
        let l:full_response = ""
        if !empty(l:thinking)
            let l:full_response = "===== THINKING TRACE =====\n\n" . l:thinking . "\n\n===== RESPONSE =====\n\n" . l:text
        else
            let l:full_response = l:text
        endif

        " Write to the response file
        call writefile(split(l:full_response, "\n"), s:response_file)

        " Return just the text content for processing
        return l:text
    else
        return "Error: Unable to get analysis from Claude API"
    endif
endfunction

function! s:GenerateDiff()
    let l:diff_command = 'diff -u ' . shellescape(s:original_file) . ' ' . shellescape(s:excerpt_file) . ' > ' . shellescape(s:excerpt_diff_file)
    call system(l:diff_command)
endfunction

function! s:ApplyChanges()
    " Save all buffers to ensure they're up to date
    wall

    " Apply the patch
    let l:patch_command = 'patch -u ' . shellescape(s:original_file) . ' -i ' . shellescape(s:excerpt_diff_file)
    let l:patch_output = system(l:patch_command)

    " Check if patch was successful
    if v:shell_error
        echohl ErrorMsg
        echo "Failed to apply patch: " . l:patch_output
        echohl None
        return
    endif

    " Reload the buffer to reflect changes
    execute "buffer " . bufnr(s:original_file)
    edit!

    " Update the end line number
    let s:end_line = line('$')

    " Ensure the cursor is on a valid line
    if line('.') > line('$')
        normal! G
    endif

    " Ensure folds are opened as they were before
    normal! zv
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
