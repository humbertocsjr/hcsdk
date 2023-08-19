HCEXE  = bin/hcexe binz80/hcexe.com bini86/hcexe.com 

bin/hcexe: hcexe/hcexe.t
	$(T3XUNIX)
binz80/hcexe.com: hcexe/hcexe.t
	$(T3XCPM)
bini86/hcexe.com: hcexe/hcexe.t
	$(T3XDOS)
