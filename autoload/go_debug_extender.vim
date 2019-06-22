" vim: foldmethod=indent

let s:save_cpo = &cpo
set cpo&vim

let s:default_breakpoint_symbol = '>'
let s:default_current_line_symbol = '='

let s:default_mappings = [
    \["nnoremap", "<F5>",  "<Plug>(go-debug-continue)"],
    \["nnoremap", "<F6>",  "<Plug>(go-debug-print)"],
    \["nnoremap", "<F9>",  "<Plug>(go-debug-breakpoint)"],
    \["nnoremap", "<F10>", "<Plug>(go-debug-next)"],
    \["nnoremap", "<F11>", "<Plug>(go-debug-step)"],
\]

function! s:reverse_dict(d)
    let l:res = {}

    for [key, value] in items(a:d)
        if has_key(l:res, value)
            let l:res[value] = add(l:res[value], key)
        else
            let l:res[value] = [key]
        endif
    endfor

    return l:res
endfunction


" Meta information, used for restoring the user's mappings to the state
" that they were before starting the debugger
let s:mappings_save = {}

" If a third argument is provided, it is used as initial value to the
" accumulator
function! s:reduce(funcname, list, ...) abort
    let F = function(a:funcname)
    let initial_provided = a:0 == 1
    let acc = initial_provided ? a:1 : a:list[0]

    for value in a:list[!initial_provided:]
        let acc = F(acc, value)
    endfor
    return acc
endfun

function! s:print_dict(d)
    for [k, v] in items(a:d)
        echo "key:\t" k
        echo "value:\t" v
        echo "\n"
    endfor
endfunction

function! s:list_to_dict(l)
    let res = {}
    for [key, val] in a:l
        let res[key] = val
    endfor
    return res
endfunction

function! go_debug_extender#Setup(...) abort
    let user_mappings = get(g:, 'go_dbg_mappings', [])

    let lhs_rhs_defaults      = s:list_to_dict(map(deepcopy(s:default_mappings),  'v:val[1:]'))
    let lhs_cmd_defaults      = s:list_to_dict(map(deepcopy(s:default_mappings),  'reverse(v:val[:1])'))

    let lhs_rhs_user_mappings = s:list_to_dict(map(deepcopy(user_mappings), 'v:val[1:]'))
    let lhs_cmd_user_mappings = s:list_to_dict(map(deepcopy(user_mappings),  'reverse(v:val[:1])'))

    " union of the mappings, the user mappings take precedence
    let l:merged_mappings = extend(s:reverse_dict(lhs_rhs_defaults), s:reverse_dict(lhs_rhs_user_mappings), 'force')
    let l:merged_commands = extend(lhs_cmd_defaults, lhs_cmd_user_mappings, 'force')

    let l:flat_mappings = s:reduce("extend", values(l:merged_mappings), [])
    let s:mappings_save = s:backup_mappings(l:flat_mappings)

    " call s:print_dict(l:merged_mappings)
    " call s:print_dict(l:merged_commands)

    for [rhs, lhss] in items(l:merged_mappings)
        for lhs in lhss
            execute join([l:merged_commands[lhs], lhs, rhs])
        endfor
    endfor
endfunction

function! go_debug_extender#DebugStart(...) abort
	call go_debug_extender#Setup()

    delcommand ExtendedGoDebugStart
    execute "GoDebugStart" join(a:000)
endfunction

function! go_debug_extender#DebugTest(...) abort
    call go_debug_extender#Setup()

    delcommand ExtendedGoDebugTest
    delcommand ExtendedGoDebugStart

    " call go#debug#Start(1, a:000)
    execute "GoDebugTest" join(a:000)
endfunction

function! s:restore_mapping(lhs, maparg_save)
    " example maparg result if mapping exists: see :h maparg()
    " {
    "   'silent': 0,
    "   'noremap': 1,
    "   'lhs': '<Space>n',
    "   'mode': 'n',
    "   'nowait': 0,
    "   'expr': 0,
    "   'sid': 2,
    "   'rhs':
    "   ':tabnew<CR>',
    "   'buffer': 0
    " }

    if empty(a:maparg_save) " see :h :unmap
        return join([maparg(a:lhs, '', 0, 1)['mode'], 'unmap'], '') . ' ' . a:lhs
    endif

    let silent_attr = get(a:maparg_save, 'silent', 0)  ? '<silent>' : ''
    let nowait_attr = get(a:maparg_save, 'no_wait', 0) ? '<nowait>' : ''
    let buffer_attr = get(a:maparg_save, 'buffer', 0)  ? '<buffer>' : ''
    let expr_attr =   get(a:maparg_save, 'expr', 0)    ? '<expr>'   : ''

    let command     = [a:maparg_save['mode'], (get(a:maparg_save, 'noremap', 0) ? 'nore' : ''), 'map']
    let command     = join(filter(command, '!empty(v:val)'), '')
    let rhs         = a:maparg_save['rhs']

    return join(filter([command, silent_attr, nowait_attr, buffer_attr, expr_attr, a:lhs, rhs], '!empty(v:val)'))
endfunction

function! go_debug_extender#Stop(...) abort
    for [lhs, save] in items(s:mappings_save)
        let command = s:restore_mapping(lhs, save)
        execute command
    endfor

    command! -nargs=* -complete=customlist,go#package#Complete ExtendedGoDebugStart call go_debug_extender#DebugStart(<f-args>)
    command! -nargs=* -complete=customlist,go#package#Complete ExtendedGoDebugTest call go_debug_extender#DebugTest(<f-args>)
    execute "GoDebugStop" join(a:000)
endfunction

function! s:backup_mappings(mappings)
    let res = {}
    for m in a:mappings
        let res[m] = maparg(m, '', 0, 1)
    endfor

    return res
endfunction

function! go_debug_extender#Breakpoint()
    silent call go#debug#Breakpoint()
    exe ":sign define godebugbreakpoint text=" . get(g:, "go_debug_breakpoint_symbol", s:default_breakpoint_symbol)
    exe ":sign define godebugcurline text=" . get(g:, "go_debug_current_line_symbol", s:default_current_line_symbol)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
