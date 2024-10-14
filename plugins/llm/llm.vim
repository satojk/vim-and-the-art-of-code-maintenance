" File: $VIM_LOCAL_PLUGINS_DIR/llm/plugin/llm.vim

if exists("g:loaded_text_analysis_focus")
    finish
endif
let g:loaded_text_analysis_focus = 1

let s:tmp_file = expand('~/vim_llm_tmp.txt')
let s:original_file = ''
let s:start_line = 0
let s:end_line = 0

function! s:CopyToTmp() range
    let s:original_file = expand('%:p')
    let s:start_line = a:firstline
    let s:end_line = a:lastline
    let l:selected_content = join(getline(a:firstline, a:lastline), "\n")
    let l:content = l:selected_content . "\n========\n\n"
    call writefile(split(l:content, "\n"), s:tmp_file)

    " Store the original filetype
    let l:original_filetype = &filetype

    " Open the new buffer in a vertical split
    execute "vsplit " . s:tmp_file

    " Set the filetype of the new buffer to match the original
    execute "setlocal filetype=" . l:original_filetype
    syntax enable

    " Move cursor to the end of the file and enter insert mode
    normal! G
    normal! o
endfunction

function! s:GetCompletion()
    let l:full_content = join(getbufline(bufnr(s:original_file), 1, '$'), "\n")
    let l:selected_content = join(getbufline(bufnr(s:original_file), s:start_line, s:end_line), "\n")

    let l:tmp_content = readfile(s:tmp_file)
    let l:split_index = index(l:tmp_content, "========")
    if l:split_index == -1
        echo "Error: Delimiter not found"
        return
    endif
    let l:user_request = join(l:tmp_content[l:split_index+1:], "\n")

    let l:response = s:GetAnalysisFromClaude(l:full_content, l:selected_content, l:user_request)

    " Check for rewrite tags
    let l:rewrite_start = stridx(l:response, "<rewrite>")
    let l:rewrite_end = stridx(l:response, "</rewrite>")

    if l:rewrite_start != -1 && l:rewrite_end != -1
        let l:rewrite = l:response[l:rewrite_start+9 : l:rewrite_end-1]
        let l:new_content = l:rewrite . "\n========\n" . l:response . "\n---\n" . l:user_request
    else
        let l:new_content = l:selected_content . "\n========\n" . l:response . "\n---\n" . l:user_request
    endif

    let l:current_filetype = &filetype
    call writefile(split(l:new_content, "\n"), s:tmp_file)
    edit!
    execute "setlocal filetype=" . l:current_filetype
    syntax enable
endfunction

function! s:GetAnalysisFromClaude(full_text, selected_text, user_request)
    let l:api_key = $ANTHROPIC_API_KEY
    if empty(l:api_key)
        return "Error: ANTHROPIC_API_KEY not set"
    endif

    let l:prompt = "Hello! I'm writing some code. Here's the full file that I have open:\n\n" . a:full_text .
                 \ "\n\nNow, focus on this selected section:\n\n" . a:selected_text .
                 \ "\n\nI have the following request about the selected section:\n" . a:user_request .
                 \ "\n\nPlease think through this step-by-step and provide a detailed response. " .
                 \ "If my request involves rewriting or modifying the selected text, " .
                 \ "please include the rewritten version at the end of your response, " .
                 \ "enclosed in <rewrite> tags."

    let l:json_data = json_encode({
        \ "model": "claude-3-5-sonnet-20240620",
        \ "max_tokens": 1500,
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
    let l:content = readfile(s:tmp_file)
    let l:split_index = index(l:content, "========")
    if l:split_index == -1
        echo "Error: Delimiter not found"
        return
    endif

    let l:new_lines = l:content[:l:split_index-1]

    " Apply the changes
    let l:tmp_bufnr = bufnr('%')
    execute "buffer " . bufnr(s:original_file)
    execute s:start_line . "," . s:end_line . "delete"
    call append(s:start_line - 1, l:new_lines)
    execute "buffer " . l:tmp_bufnr

    " Update the end line number
    let s:end_line = s:start_line + len(l:new_lines) - 1

    echo "Changes applied to original file."
endfunction

command! -range Llm <line1>,<line2>call <SID>CopyToTmp()
command! Ask call <SID>GetCompletion()
command! Apply call <SID>ApplyChanges()
