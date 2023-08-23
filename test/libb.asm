proc _start
    call main
    ld e, 65
    ld c, 2
    call 5
    jp 0
endproc _start

proc putchar
    ld e, 65
    ld c, 2
    call 5
    ret
endproc putchar