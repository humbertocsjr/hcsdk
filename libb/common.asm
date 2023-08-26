

; Code from T3X/0 Z80 cmp16s
proc cmp16
    xor  a
	sbc  hl,de
	ret  z
	jp   pe, csv1
	jp   m, cs1
label cs0
	or   a
	ret
label csv1
	jp   p,cs0
label cs1
	scf
    ret
endproc cmp16