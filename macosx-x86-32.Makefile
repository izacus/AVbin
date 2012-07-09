LIBNAME=$(OUTDIR)/libavbin.$(AVBIN_VERSION).dylib
DARWIN_VERSION=$(shell uname -r | cut -d . -f 1)

CFLAGS += -O3 -mmacosx-version-min=10.6 -arch i386
LDFLAGS += -dylib \
           -single_module \
           -macosx_version_min 10.6 \
           -arch i386 \
           -read_only_relocs suppress \
           -install_name @rpath/libavbin.dylib

STATIC_LIBS = $(LIBAV)/libavformat/libavformat.a \
              $(LIBAV)/libavcodec/libavcodec.a \
              $(LIBAV)/libavutil/libavutil.a \
              $(LIBAV)/libswscale/libswscale.a

LIBS = -lSystem \
       -lz \
       -lbz2 \

$(LIBNAME) : $(OBJNAME) $(OUTDIR)
	$(LD) $(LDFLAGS) -o $@ $< $(STATIC_LIBS) $(LIBS)