proc _start
    call main
    jp 0
endproc _start

proc putchar
    push ix
    ld ix, 0
    add ix, sp
    ld e, (ix+4)
    ld c, 2
    call 5
    pop ix
    ret
endproc putchar
