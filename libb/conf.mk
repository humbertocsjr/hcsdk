LIBB  = bin/libb.cpm binz80/libb.cpm bini86/libb.cpm bin/libb.msx binz80/libb.msx bini86/libb.msx bin/libb.z80 binz80/libb.z80 bini86/libb.z80

LIBB_FILES_MIN = libb/common.obj libb/putstr.obj 
LIBB_FILES = $(LIBB_FILES_MIN)

libb/%.obj:libb/%.asm
	@bin/hcasmz80 $(patsubst %.asm,%,$<)

libb/%.obj:libb/%.b
	@bin/hcb $(patsubst %.b,%,$<)
	@bin/hcbz80 $(patsubst %.b,%,$<)

libb/libbcpm.lib: libb/oscpm.obj $(LIBB_FILES)
	@bin/hclink lib $(patsubst %.lib,%,$@) $^

libb/libbmsx.lib: libb/osmsx.obj $(LIBB_FILES)
	@bin/hclink lib $(patsubst %.lib,%,$@) $^

libb/libbz80.lib: libb/osz80.obj $(LIBB_FILES_MIN)
	@bin/hclink lib $(patsubst %.lib,%,$@) $^

bin/libb.cpm: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbcpm.lib
	@cp libb/libbcpm.lib $@
binz80/libb.cpm: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbcpm.lib
	@cp libb/libbcpm.lib $@
bini86/libb.cpm: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbcpm.lib
	@cp libb/libbcpm.lib $@

bin/libb.msx: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbmsx.lib
	@cp libb/libbmsx.lib $@
binz80/libb.msx: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbmsx.lib
	@cp libb/libbmsx.lib $@
bini86/libb.msx: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbmsx.lib
	@cp libb/libbmsx.lib $@

bin/libb.z80: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbz80.lib
	@cp libb/libbz80.lib $@
binz80/libb.z80: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbz80.lib
	@cp libb/libbz80.lib $@
bini86/libb.z80: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbz80.lib
	@cp libb/libbz80.lib $@