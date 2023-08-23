
test: all
	bin/hcb test/test
	bin/hcbz80 test/test
	bin/hcexe test/test test/test.obj bin/cpmz80.lib
	bin/hclink com test/test test/test.lib
	z80dasm -a test/test.com