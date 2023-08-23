LIBB  = bin/libb.cpm binz80/libb.cpm bini86/libb.cpm

libb/%.obj:libb/%.asm
	@bin/hcasmz80 $(patsubst %.asm,%,$<)

libb/%.obj:libb/%.b
	@bin/hcb $(patsubst %.b,%,$<)
	@bin/hcbz80 $(patsubst %.b,%,$<)

libb/libbcpm.lib: libb/oscpm.obj libb/putstr.obj
	@bin/hclink lib $(patsubst %.lib,%,$@) $^

bin/libb.cpm: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbcpm.lib
	@cp libb/libbcpm.lib $@
binz80/libb.cpm: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbcpm.lib
	@cp libb/libbcpm.lib $@
bini86/libb.cpm: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/libbcpm.lib
	@cp libb/libbcpm.lib $@