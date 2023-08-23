
distro: all distro/msx720.dsk distro/dos1440.img

distro/msx720.dsk: $(wildcard binz80/*.com) $(wildcard distro/msx.*) $(wildcard test/*)
	dd if=/dev/zero of=$@ bs=1024 count=720
	mformat -f 720 -i $@
	dd if=distro/msxbin/BOOT of=$@ bs=512 count=1 conv=notrunc
	mcopy -i $@ distro/msxbin/MSXDOS.SYS ::/MSXDOS.SYS
	mcopy -i $@ distro/msxbin/COMMAND.COM ::/COMMAND.COM
	mcopy -i $@ binz80/* ::/
	mcopy -i $@ test/*.b ::/
	mcopy -i $@ test/*.asm ::/
	mcopy -i $@ distro/msx.bat ::/BUILD.BAT
	mcopy -i $@ distro/msx.md ::/README.MD

distro/dos1440.img: $(wildcard bini86/*.com) $(wildcard distro/dos.*) $(wildcard test/*)
	dd if=/dev/zero of=$@ bs=1024 count=1440
	mformat -f 1440 -i $@
	mcopy -i $@ bini86/* ::/
	mcopy -i $@ test/*.b ::/
	mcopy -i $@ test/*.asm ::/


