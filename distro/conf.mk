
distro: all distro/msx720.dsk distro/dos1440.img

distro/msx720.dsk: binz80/hcb.com binz80/hcbz80.com binz80/hclink.com distro/msx.md
	dd if=/dev/zero of=$@ bs=1024 count=720
	mformat -f 720 -i $@
	dd if=distro/msxbin/BOOT of=$@ bs=512 count=1 conv=notrunc
	mcopy -i $@ distro/msxbin/MSXDOS.SYS ::/MSXDOS.SYS
	mcopy -i $@ distro/msxbin/COMMAND.COM ::/COMMAND.COM
	mcopy -i $@ binz80/hcb.com ::/HCB.COM
	mcopy -i $@ binz80/hcbz80.com ::/HCBZ80.COM
	mcopy -i $@ binz80/hclink.com ::/HCLINK.COM
	mcopy -i $@ test/test.b ::/TEST.B
	mcopy -i $@ distro/msx.md ::/README.MD

distro/dos1440.img: bini86/hcb.com bini86/hcbz80.com bini86/hclink.com
	dd if=/dev/zero of=$@ bs=1024 count=1440
	mformat -f 1440 -i $@
	mcopy -i $@ binz80/hcb.com ::/HCB.COM
	mcopy -i $@ binz80/hcbz80.com ::/HCBZ80.COM
	mcopy -i $@ binz80/hclink.com ::/HCLINK.COM
	mcopy -i $@ test/test.b ::/TEST.B


