# vim-go-extensions

This plugin extends the awesome [fatih/vim-go](https://github.com/fatih/vim-go) plugin, with the following features:

## Features
* Add key mappings only for when the debugger is active
* `:GoListBreakpoints` to show breakpoints in the quickfix window
* `:GoClearAllBreakpoints` to clear all breakpoints
* `:GoClearFileBreakpoints` to clear breakpoints just in the current file

![Showcase GIF](https://user-images.githubusercontent.com/17802702/60736923-6b28f080-9f61-11e9-8f90-8e353bfce819.gif)

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
Those mappings will activate upon executing `:ExtendedGoDebugStart` or `:ExtendedGoDebugTest` and will restore your previous
bindings once the `:ExtendedGoDebugStop` command is executed, so in the example above vim's builtin `c` semantics will
be restored once the debugger session ends

## Options

* g:go_debug_autoupdate_quickfix_breakpoints

    Controls the autoupdating of the quickfix window, 1 (on) by default

* g:go_debug_breakpoint_symbol, example
    
    ```
    let g:go_debug_breakpoint_symbol='👻'
    ```

* g:go_debug_current_line_symbol, example

    ```
    let g:go_debug_current_line_symbol='💩'
    ```

    You have to use `:ExtendedGoDebugBreakpoint` instead of `:GoDebugBreakpoint` for symbols to work,
    atleast on neovim.

## License

The BSD 3-Clause License - see [LICENSE](https://github.com/kernel-panic96/vim-go-debug-extender/blob/master/LICENSE) for more details
