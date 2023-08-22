HCASM  = bin/hcasmz80 binz80/hcasmz80.com bini86/hcasmz80.com

bin/hcasmz80: hcasm/hcasmz80.t library/hcltks.t library/hcasm.t library/hcatks.t
	$(T3XUNIX)
binz80/hcasmz80.com: hcasm/hcasmz80.t library/hcltks.t library/hcasm.t library/hcatks.t
	$(T3XCPM)
bini86/hcasmz80.com: hcasm/hcasmz80.t library/hcltks.t library/hcasm.t library/hcatks.t
	$(T3XDOS)
