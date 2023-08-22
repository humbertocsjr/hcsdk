all: bin binz80 bini86 build

T3XPATH = /usr/local/t3x/0/

T3XUNIX = tx0 -t unix $(patsubst %.t,%,$<) $@
T3XCPM = $(T3XPATH)tx-cpm $(patsubst %.t,%,$<) $(patsubst %.com,%,$@)
T3XDOS = $(T3XPATH)tx-dos $(patsubst %.t,%,$<) $(patsubst %.com,%,$@)

include hcb/conf.mk
include hcasm/conf.mk
include hclink/conf.mk
include hcexe/conf.mk
include test/conf.mk
include distro/conf.mk

bin: 
	mkdir -p bin

binz80: 
	mkdir -p binz80

bini86: 
	mkdir -p bini86

build: $(HCB) $(HCASM) $(HCLINK) $(HCEXE)


clean:
	-rm bin/*
	-rm bini86/*
	-rm binz80/*
	-rm distro/*.img
	-rm distro/*.dsk
	-rm test/*.btk
	-rm test/*.obj
	-rm test/*.bin
	-rm test/*.lib
	-rm test/*.com