command! -nargs=* -complete=customlist,go#package#Complete MyGoDebugStart call go_debug_extender#DebugStart(<f-args>)
command! -nargs=* -complete=customlist,go#package#Complete MyGoDebugTest call go_debug_extender#DebugTest(<f-args>)
command! -nargs=* -complete=customlist,go#package#Complete MyGoDebugStop call go_debug_extender#Stop(<f-args>)
command! MyGoDebugBreakpoint call go_debug_extender#Breakpoint()
