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

function! utils#ReverseDict(d)
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

function! utils#ListToDict(l)
    let res = {}
    for [key, val] in a:l
        let res[key] = val
    endfor
    return res
endfunction

" If a third argument is provided, it is used as initial value to the
" accumulator
function! utils#Reduce(funcname, list, ...) abort
    let F = function(a:funcname)
    let initial_provided = a:0 == 1
    let acc = initial_provided ? a:1 : a:list[0]

    for value in a:list[!initial_provided:]
        let acc = F(acc, value)
    endfor
    return acc
endfun

function! utils#PrintDict(d)
    for [k, v] in items(a:d)
        echo "key:\t" k
        echo "value:\t" v
        echo "\n"
    endfor
endfunction
