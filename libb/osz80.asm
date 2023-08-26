proc _start
    call main
    label _start_loop
    hlt
    jp _start_loop
endproc _start