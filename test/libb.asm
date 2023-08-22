
proc _start
    ld a,b
    ld b, a
    ld d, c
    ld a, (hl)
    ld (hl), b
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
endproc putchar