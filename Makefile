# Makefile for STD.pm viv etcetera in pugs/src/perl6
.PHONY: check try cat clean distclean purge test

FIXINS=Cursor.pmc LazyMap.pm lib/DEBUG.pm DEBUG.pmc lib/Test.pm \
	CORE.setting NULL.pad std mangle.pl CORE.pad lib/NAME.pm NAME.pmc \
	lib/Stash.pm Stash.pmc sprixel.pl ToJS.pm viv sprixelCORE.setting

all: $(FIXINS) check lex/STD/termish

fast: $(FIXINS) check

snap: $(FIXINS) check lex/STD/termish
	rm -rf snap.new
	mkdir snap.new
	@#svn info |grep ^Revision|cut -d' ' -f2  > snap.new/revision
	svn info |perl -ne 'print "$1\n" if /Revision:\s+(\d+)/' > snap.new/revision
	cp $(FIXINS)  tryfile STD.pmc STD_P5.pmc *.syml CORE.*.store snap.new
	-cp -r lib snap.new
	-cp -r setting snap.new
	-cp -r sprixel snap.new
	-cp -r lex snap.new
	-rm -rf snap.old
	-mv snap snap.old
	mv snap.new snap

STD_P5.pmc: STD_P5.pm gimme5
	perl gimme5 $< >STD_P5.pm5
	perl -p -e 'next if /^---/../\A\w+\Z/;' -e 's/\A[ \t]+//;' STD_P5.pm5 >$@

STD.pmc: STD.pm gimme5
	perl gimme5 $< >STD.pm5
	perl -p -e 'next if /^---/../\A\w+\Z/;' -e 's/\A[ \t]+//;' STD.pm5 >$@
	rm -rf lex *.pad.store

CORE.syml: CORE.setting
	-rm CORE.syml.store
	-./std CORE.setting

check: STD.pmc STD_P5.pmc
	/usr/local/bin/perl -c STD.pmc
	/usr/local/bin/perl -c STD_P5.pmc

# pre-generate common sublexers
lex/STD/termish: STD.pmc STD_P5.pmc CORE.syml
	@echo 'Generating STD lexers...'
	./tryfile STD.pm

cat:
	cat try5.out

clean:
	rm -rf lex try5.* *.pad.store *.syml.store *.syml STD.pmc STD_P5.pmc STD.pm5 STD_P5.pm5

# purge is an alias for distclean
distclean purge: clean
	rm -rf STD.pmc STD_P5.pmc STD.pm5

snaptest: snap all
	cd snap; ../teststd ../../../t

test: all
	./teststd
testt: all
	./teststd ../../t

# List all targets with brief descriptions.
# Gradual shaving of targets with Occam's Razor would be a Good Thing.
help:
	@echo
	@echo 'In pugs/src/perl6 you can make these targets:'
	@echo
	@echo 'all (default)   builds viv'
	@echo 'fast            same as check'
	@echo 'snap            copies runnable files and svn revision to snap/'
	@echo 'STD_P5.pmc      (internal)'
	@echo 'STD.pmc         (internal)'
	@echo 'CORE.syml       (internal)'
	@echo 'check           verifies Perl 5 syntax of STD.pmc and STD_P5.pmc'
	@echo 'lex/STD/termish (internal)'
	@echo 'cat             shows the output written by the last tryfile'
	@echo 'clean           removes many generated files'
	@echo 'distclean       removes even more generated files'
	@echo 'purge           alias for distclean'
	@echo 'snaptest        run snapshot teststd on pugs/t/spec/*'
	@echo 'test            run teststd on pugs/t/*'
	@echo 'testt           run teststd on pugs/t/spec/*'
	@echo 'help            show this list'
	@echo
