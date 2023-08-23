LIBB  = bin/cpmz80.lib binz80/cpmz80.lib bini86/cpmz80.lib

libb/%.obj:libb/%.asm
	@bin/hcasmz80 $(patsubst %.asm,%,$<)

libb/%.obj:libb/%.b
	@bin/hcb $(patsubst %.b,%,$<)
	@bin/hcbz80 $(patsubst %.b,%,$<)

libb/cpmz80.lib: libb/oscpm.obj libb/putstr.obj
	@bin/hclink lib libb/cpmz80 $^

bin/cpmz80.lib: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/cpmz80.lib
	@cp $^ $@
binz80/cpmz80.lib: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/cpmz80.lib
	@cp $^ $@
bini86/cpmz80.lib: bin/hclink bin/hcasmz80 bin/hcb bin/hcbz80 libb/cpmz80.lib
	@cp $^ $@