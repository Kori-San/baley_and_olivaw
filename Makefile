PREFIX = /usr

all:
	@echo Run \'make install\' to install Baley and Olivaw
	@echo Run \'make uninstall\' to uninstall Baley and Olivaw.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p baley.sh $(DESTDIR)$(PREFIX)/bin/baley
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/baley

	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p olivaw.sh $(DESTDIR)$(PREFIX)/bin/olivaw
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/olivaw

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/baley
	@rm -rf $(DESTDIR)$(PREFIX)/bin/olivaw
