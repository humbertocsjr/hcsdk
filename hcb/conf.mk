HCB  = bin/hcb binz80/hcb.com bini86/hcb.com bin/hcbz80 binz80/hcbz80.com bini86/hcbz80.com

bin/hcb: hcb/hcb.t library/hcbtks.t
	$(T3XUNIX)
binz80/hcb.com: hcb/hcb.t library/hcbtks.t
	$(T3XCPM)
bini86/hcb.com: hcb/hcb.t library/hcbtks.t
	$(T3XDOS)

bin/hcbz80: hcb/hcbz80.t library/hcbcomp.t library/hcbtks.t library/hcltks.t
	$(T3XUNIX)
binz80/hcbz80.com: hcb/hcbz80.t library/hcbcomp.t library/hcbtks.t library/hcltks.t
	$(T3XCPM)
bini86/hcbz80.com: hcb/hcbz80.t library/hcbcomp.t library/hcbtks.t library/hcltks.t
	$(T3XDOS)
