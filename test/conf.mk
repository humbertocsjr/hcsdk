
test: all
	bin/hcb test/test
	bin/hcbz80 test/test
	bin/hcexe test/test test/test.obj bin/libb.cpm
	bin/hclink com test/test test/test.lib
	bin/hcexe test/test test/test.obj bin/libb.msx
	bin/hclink msx test/test test/test.lib
	z80dasm -a test/test.com