CFLAGS += -g -Wall -Wstrict-prototypes -I .
CFLAGS += -DDEBUG_SUPPORT -DDEBUG_DEFAULT 
CFLAGS += $(UCFLAGS)


pkgdir = $(libdir)
pkg_LTLIBRARIES=libiax.la
libiax_la_SOURCES = iax.c md5.c 
EXTRA_DIST = md5.h frame.h iax-client.h iax.h

install:
	mkdir -p $(includedir)/iax
	install -m 644 md5.h $(includedir)/iax
	install -m 644 frame.h $(includedir)/iax
	install -m 644 iax.h $(includedir)/iax
	install -m 644 iax-client.h $(includedir)/iax
	/sbin/ldconfig

