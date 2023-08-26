proc _start
    useproc _start2
    db "AB"
    dw _start2
    db 0,0,0,0,0,0
endproc _start

proc _start2
    call main
    label _start2_loop
    jp _start2_loop
endproc _start2

proc putchar
    push ix
    ld ix, 0
    add ix, sp
    ld a, (ix+4)
    call 162
    pop ix
    ret
endproc putchar

