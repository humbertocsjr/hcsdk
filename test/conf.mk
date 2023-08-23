
test: all
	bin/hcb test/test
	bin/hcbz80 test/test
	bin/hcasmz80 test/libb
	bin/hcexe test/test test/test.obj test/libb.obj
	bin/hclink com test/test test/test.lib
	z80dasm -a test/test.com