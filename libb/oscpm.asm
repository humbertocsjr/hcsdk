proc _start
    call main
    jp 0
endproc _start

proc teststring
    ld e, 'T'
    ld c, 2
    call 5
    ld e, 'E'
    ld c, 2
    call 5
    ld e, 'S'
    ld c, 2
    call 5
    ld e, 'T'
    ld c, 2
    call 5
    ret
endproc putchar