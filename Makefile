include ./config/make.MPI.inc

AR = ar -rvcu
RANLIB = ranlib
VERSION := 1.0
LIBS ?= $(LIBPETSC) $(LIBSLEPC)

ifeq ($(UNAME), Darwin)
	SLIB ?= dylib
	SONAMELIB ?= libGCGE.${VERSION}.${SLIB}
	SOFLAGS ?= -dynamiclib -Wl,-install_name,$(SONAMELIB) -current_version $(VERSION) -Wl,-undefined -Wl,dynamic_lookup
	LDFLAGS = -Wl,-framework -Wl,Accelerate -m64
else
	SLIB ?= so
	SONAMELIB ?= libGCGE.$(SLIB).$(VERSION)
	SOFLAGS ?= -shared -Wl,-soname,$(SONAMELIB)
	LDFLAGS =
endif

GCGE_DIRS = app src
GCGE_HEADERS = $(wildcard app/*.h src/*.h)
GCGE_OBJS = $(wildcard lib/*.o)
GCGE_LIB = libGCGE.a
GCGE_SOLIB = libGCGE.${SLIB}

all: $(GCGE_LIB) $(GCGE_SOLIB)
	@mkdir -p include
	@cp -fp $(GCGE_HEADERS) include
	@$(RM) $(GCGE_OBJS)

objects:
	@mkdir -p lib; \
	$(MAKE) -C test; \
	for i in $(GCGE_DIRS); \
	do \
		cp -fp $$i/*.o ./lib/; \
	done

$(GCGE_LIB): objects
	@echo "Building $@ ..."
ifeq ($(UNAME), Darwin)
	@cd lib && libtool -static -o $@ *.o -no_warning_for_no_symbols
else
	@cd lib && $(AR) $@ ./*.o
	@cd lib && $(RANLIB) $@
endif

$(GCGE_SOLIB): objects
	@echo "Building $@ ..."
ifeq ($(UNAME), Darwin)
	@$(CC) $(SOFLAGS) $(GCGE_OBJS) -o lib/$(SONAMELIB) $(LDFLAGS) $(LIBS)
else
	@$(CC) $(SOFLAGS) -o lib/$(SONAMELIB) -Wl,--whole-archive $(GCGE_OBJS) -Wl,--no-whole-archive $(LDFLAGS) $(LIBS)
endif

ifneq ($(SONAMELIB), $(GCGE_SOLIB))
	@ln -sf lib/$(SONAMELIB) lib/$(GCGE_SOLIB)
endif

clean:
	-@$(RM) -r include lib
	-@$(MAKE) -C example clean
	-@$(MAKE) -C test clean

.PHONY: all objects clean
