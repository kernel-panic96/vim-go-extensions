# vim-go-extensions

## Features

This plugin extends the awesome [fatih/vim-go](https://github.com/fatih/vim-go) plugin, with the following features:

* Add key mappings only for when the debugger is active
* `:GoListBreakpoints` to show breakpoints in the quickfix window
* `:GoClearAllBreakpoints` to clear all breakpoints
* `:GoClearFileBreakpoints` to clear breakpoints just in the current file
* Commands for clearing of all/file specific breakpoints

## Install

vim-go-extensions requires [vim-go](https://github.com/fatih/vim-go)

* Vundle
    * `Plugin 'kernel-panic96/vim-go-extensions'`

## Usage

##### Defining debug mode specific mappings

```vimscript
let g:go_debug_mappings = [
    \['nmap <nowait>',  'c', '<Plug>(go-debug-continue)'],
    \['nmap',           'q', ':ExtendedGoDebugStop<CR>'],
    \['nmap <nowait>',  'n', '<Plug>(go-debug-next)'],
    \['nmap',           's', '<Plug>(go-debug-step)'],
\]
```
Those mappings will activate when the debugger is active and will restore your previous
bindings once the `:ExtendedGoDebugStop` command is executed, so in the example above vim's builtin `c` mapping will
be restored once the debugger session ends


##### Other miscellaneous features

Changing the breakpoint and debugger current line  symbols:

```
let g:go_debug_breakpoint_symbol='👻'
let g:go_debug_current_line_symbol='💩'
```

You have to use `:ExtendedGoDebugBreakpoint` instead of `:GoDebugBreakpoint` for that to work,
atleast on neovim.

## License

The BSD 3-Clause License - see [LICENSE](https://github.com/kernel-panic96/vim-go-debug-extender/blob/master/LICENSE) for more details
