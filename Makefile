.PHONY: all install-d2

all: current.svg highlevel.svg lowlevel.svg highlevel-new.d2

%.svg: %.d2
	d2 $< $@

install-d2:
	go install oss.terrastruct.com/d2
