
distro: all distro/msx720.dsk distro/dos1440.img

distro/msx720.dsk: binz80/hcb.com binz80/hcbz80.com binz80/hcexe.com binz80/hclink.com distro/msx.md
	dd if=/dev/zero of=$@ bs=1024 count=720
	mformat -f 720 -i $@
	dd if=distro/msxbin/BOOT of=$@ bs=512 count=1 conv=notrunc
	mcopy -i $@ distro/msxbin/MSXDOS.SYS ::/MSXDOS.SYS
	mcopy -i $@ distro/msxbin/COMMAND.COM ::/COMMAND.COM
	mcopy -i $@ binz80/*.com ::/
	mcopy -i $@ test/*.b ::/
	mcopy -i $@ distro/msx.md ::/README.MD

distro/dos1440.img: bini86/hcb.com bini86/hcbz80.com bini86/hcexe.com bini86/hclink.com
	dd if=/dev/zero of=$@ bs=1024 count=1440
	mformat -f 1440 -i $@
	mcopy -i $@ bini86/*.com ::/
	mcopy -i $@ test/*.b ::/


