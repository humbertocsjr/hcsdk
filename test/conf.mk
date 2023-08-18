
test: all
	bin/hcb test/test
	bin/hcbz80 test/test
	bin/hcb test/libtest
	bin/hcbz80 test/libtest
	bin/hclink com test/test test/test.obj test/libtest.obj
	z80dasm -a test/test.com