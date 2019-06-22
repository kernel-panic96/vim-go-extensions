function! utils#ListBreakpoints()
    " This function is copy-pasted from vim-go/autoload/go/debug.vim
    " because it's not exported

    " :sign place
    " --- Signs ---
    " Signs for a.go:
    "     line=15  id=2  name=godebugbreakpoint
    "     line=16  id=1  name=godebugbreakpoint
    " Signs for a_test.go:
    "     line=6  id=3  name=godebugbreakpoint

    let l:signs = []
    let l:file = ''
    for l:line in split(execute('sign place'), '\n')[1:]
        if l:line =~# '^Signs for '
            let l:file = l:line[10:-2]
            continue
        endif

        if l:line !~# 'name=godebugbreakpoint'
            continue
        endif

        let l:sign = matchlist(l:line, '\vline\=(\d+) +id\=(\d+)')
        call add(l:signs, {
                    \ 'id': l:sign[2],
                    \ 'file': fnamemodify(l:file, ':p'),
                    \ 'line': str2nr(l:sign[1]),
                    \ })
    endfor

    return l:signs
endfunction
