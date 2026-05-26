PREFIX ?= /usr/local

install:
	install -m 755 skel.sh $(DESTDIR)$(PREFIX)/bin/skel

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/skel

test:
	bash test.sh

.PHONY: install uninstall test
