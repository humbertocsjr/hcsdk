HCLINK  = bin/hclink binz80/hclink.com bini86/hclink.com 

bin/hclink: hclink/hclink.t
	$(T3XUNIX)
binz80/hclink.com: hclink/hclink.t
	$(T3XCPM)
bini86/hclink.com: hclink/hclink.t
	$(T3XDOS)
