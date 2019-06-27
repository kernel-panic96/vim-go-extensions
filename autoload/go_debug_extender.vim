" vim: foldmethod=indent

" The idea of the ExtendedGoDebugStart/Test/Stop is to provide a 'debug vim mode' 
" as in vim's normal or insert mode, which allows the user to have key mappings
" only when the debugger is active.
"
" This is done by wrapping vim-go's Start;Test;Stop commands
" saving the user mappings as of the time of the `Start`
" and restoring them during the `Stop`

let s:save_cpo = &cpo
set cpo&vim

let s:default_breakpoint_symbol = '>'
let s:default_current_line_symbol = '='
let s:breakpoints = {}
" Meta information about the user's mappings, used for the mapping restoration
let s:mappings_save = {}

if !exists('g:go_debug_autoupdate_quickfix_breakpoints')
    let g:go_debug_autoupdate_quickfix_breakpoints = 0
endif

let s:default_mappings = [
    \["nnoremap", "<F5>",  "<Plug>(go-debug-continue)"],
    \["nnoremap", "<F6>",  "<Plug>(go-debug-print)"],
    \["nnoremap", "<F9>",  "<Plug>(go-debug-breakpoint)"],
    \["nnoremap", "<F10>", "<Plug>(go-debug-next)"],
    \["nnoremap", "<F11>", "<Plug>(go-debug-step)"],
\]

" Example user's mappings:
"
" let g:go_debug_mappings = [
"     \['nmap <nowait>',  'c', '<Plug>(go-debug-continue)'],
"     \['nmap',           'q', ':ExtendedGoDebugStop<CR>'],
"     \['nmap <nowait>',  'n', '<Plug>(go-debug-next)'],
"     \['nmap',           's', '<Plug>(go-debug-step)'],
" \]

function! go_debug_extender#Setup(...) abort
    " converts the s:default_mappings and g:go_debug_mappings (user specified mappings)
    " to appropriate formats for merging of the mappings.

    " The need for merge of the mappings is performed in order to fill potential gaps
    " in the user specified mappings. For example, if the user didn't set up
    " a mapping for <Plug>(go-debug-continue) the one in s:default_mappings
    " will be used.
    "
    " After the merge a save of the user's mappings is performed, e.g. if the
    " user remapped 'c' to <Plug>(go-debug-continue), the original meaning of
    " 'c' will be saved. That is done so it can be restored to its original
    " meaning during the Stop()

    " User mappings are not limited to <Plug>(go*) rhs's (see h: rhs), anything could be mapped
    " and the user could have more that one mapping for a particular <Plug>(go*) rhs

    let user_mappings = get(g:, 'go_debug_mappings', [])

    let lhs_rhs_defaults      = utils#ListToDict(map(deepcopy(s:default_mappings),  'v:val[1:]'))
    let lhs_cmd_defaults      = utils#ListToDict(map(deepcopy(s:default_mappings),  'reverse(v:val[:1])'))

    let lhs_rhs_user_mappings = utils#ListToDict(map(deepcopy(user_mappings), 'v:val[1:]'))
    let lhs_cmd_user_mappings = utils#ListToDict(map(deepcopy(user_mappings),  'reverse(v:val[:1])'))

    " The first ReverseDict will return a Dict with rhs as key and List of lhs's,
    " because there may be more than one lhs that maps to a rhs.
    " Then a union of the mappings is performed by extend and the user mappings take precedence
    let l:merged_mappings = extend(utils#ReverseDict(lhs_rhs_defaults), utils#ReverseDict(lhs_rhs_user_mappings), 'force')
    let l:merged_commands = extend(lhs_cmd_defaults, lhs_cmd_user_mappings, 'force')

    let l:flat_mappings = utils#Reduce("extend", values(l:merged_mappings), []) " gets all the lhs's
    let s:mappings_save = s:backup_mappings(l:flat_mappings)

    for [rhs, lhss] in items(l:merged_mappings)
        for lhs in lhss
            execute join([l:merged_commands[lhs], lhs, rhs])
        endfor
    endfor
endfunction

function! go_debug_extender#DebugStart(...) abort
	call go_debug_extender#Setup()

    delcommand ExtendedGoDebugStart " a second start will break the restoration
    delcommand ExtendedGoDebugTest

    execute "GoDebugStart" join(a:000)
endfunction

function! go_debug_extender#DebugTest(...) abort
    call go_debug_extender#Setup()

    delcommand ExtendedGoDebugTest
    delcommand ExtendedGoDebugStart

    " call go#debug#Start(1, a:000)
    execute "GoDebugTest" join(a:000)
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

function! s:restore_mapping(lhs, maparg_save)
    " example maparg result if the mapping exists; see :h maparg()
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

function! go_debug_extender#Breakpoint(...)
    silent call call(function('go#debug#Breakpoint'), a:000)

    call s:sync_breakpoint()

    if g:go_debug_autoupdate_quickfix_breakpoints
        call go_debug_extender#PopulateQuickfix()
    endif

    exe ":sign define godebugbreakpoint text=" . get(g:, "go_debug_breakpoint_symbol", s:default_breakpoint_symbol)
    exe ":sign define godebugcurline text=" . get(g:, "go_debug_current_line_symbol", s:default_current_line_symbol)
endfunction

function! s:sync_breakpoint()
    let l:file = expand('%:p')
    let l:lines = split(execute('sign place file=' . file), '\n')[2:]

    let l:file_bps = {}
    for l:line in l:lines
        if l:line !~# 'name=godebugbreakpoint'
            continue
        endif

        let l:sign = matchlist(l:line, '\vline\=(\d+) +id\=(\d+)')
        let [l:line, l:id] = [str2nr(l:sign[1]), str2nr(l:sign[2])]

        let l:file_bps[l:line] = l:id
    endfor

    let s:breakpoints[l:file] = l:file_bps

    for [k, v] in items(s:breakpoints)
        if len(v) == 0
            call remove(s:breakpoints, k)
        endif
    endfor
endfunction

function! go_debug_extender#PopulateQuickfix()
    if len(s:breakpoints) == 0
        call setqflist([])
        exe 'cclose'
        return
    endif

    call setqflist([], ' ', {'title': 'Breakpoints'})
    for [l:file, l:line_dict] in sort(items(s:breakpoints))
        let l:keys = keys(l:line_dict)
        for l:lnum in sort(keys(l:line_dict), 'N')
            let l:line = getbufline(bufname(file), l:lnum)
            call setqflist([{'filename': l:file, 'lnum': l:lnum, 'text': l:line[0]}] , 'a')
        endfor
    endfor
endfunction

function! go_debug_extender#ClearAllBreakpoints(...)
    let l:file = ''
    if len(a:000) > 0
        let l:file = a:1
    endif

    let l:breakpoints = utils#ListBreakpoints()

    for bp in l:breakpoints 
        if l:file != ''
            if l:file == bp['file']
                call go_debug_extender#Breakpoint(bp['line'], bp['file'])
            endif
        else
            call go_debug_extender#Breakpoint(bp['line'], bp['file'])
        endif
    endfor
endfunction

function! go_debug_extender#QuickfixBreakpoints()
    call go_debug_extender#PopulateQuickfix()
    if len(s:breakpoints)
        silent execute 'copen'
    else
        echo "There are no breakpoints"
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
