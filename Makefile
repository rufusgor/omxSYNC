CFLAGS=-pipe
CFLAGS+=-mfloat-abi=hard
CFLAGS+=-mcpu=arm1176jzf-s
CFLAGS+=-fomit-frame-pointer
CFLAGS+=-mabi=aapcs-linux
CFLAGS+=-mtune=arm1176jzf-s
CFLAGS+=-mfpu=vfp
CFLAGS+=-Wno-psabi
CFLAGS+=-mno-apcs-stack-check
CFLAGS+=-g
CFLAGS+=-mstructure-size-boundary=32
CFLAGS+=-mno-sched-prolog
CFLAGS+=-std=c++0x
CFLAGS+=-D__STDC_CONSTANT_MACROS
CFLAGS+=-D__STDC_LIMIT_MACROS
CFLAGS+=-DTARGET_POSIX
CFLAGS+=-DTARGET_LINUX
CFLAGS+=-fPIC
CFLAGS+=-DPIC
CFLAGS+=-D_REENTRANT
CFLAGS+=-D_LARGEFILE64_SOURCE
CFLAGS+=-D_FILE_OFFSET_BITS=64
CFLAGS+=-DHAVE_CMAKE_CONFIG
CFLAGS+=-D__VIDEOCORE4__
CFLAGS+=-U_FORTIFY_SOURCE
CFLAGS+=-Wall
CFLAGS+=-DHAVE_OMXLIB
CFLAGS+=-DUSE_EXTERNAL_FFMPEG
CFLAGS+=-DHAVE_LIBAVCODEC_AVCODEC_H
CFLAGS+=-DHAVE_LIBAVUTIL_OPT_H
CFLAGS+=-DHAVE_LIBAVUTIL_MEM_H
CFLAGS+=-DHAVE_LIBAVUTIL_AVUTIL_H
CFLAGS+=-DHAVE_LIBAVFORMAT_AVFORMAT_H
CFLAGS+=-DHAVE_LIBAVFILTER_AVFILTER_H
CFLAGS+=-DHAVE_LIBSWRESAMPLE_SWRESAMPLE_H
CFLAGS+=-DOMX
CFLAGS+=-DOMX_SKIP64BIT
CFLAGS+=-ftree-vectorize
CFLAGS+=-DUSE_EXTERNAL_OMX
CFLAGS+=-DTARGET_RASPBERRY_PI
CFLAGS+=-DUSE_EXTERNAL_LIBBCM_HOST
#CFLAGS+=-ggdb #Remove for production
#CFLAGS+=-Q #Remove for production
#CFLAGS+=-v #Remove for production
#CFLAGS+=-da #Remove for production
#CFLAGS+=-fsanitize=address #Remove for production

LDFLAGS=-L$(SDKSTAGE)/opt/vc/lib/
LDFLAGS+=-L./
LDFLAGS+=-Lffmpeg_compiled/usr/local/lib/
LDFLAGS+=-lc
LDFLAGS+=-lbrcmGLESv2
LDFLAGS+=-lbrcmEGL
LDFLAGS+=-lbcm_host
LDFLAGS+=-lopenmaxil
LDFLAGS+=-lfreetype
LDFLAGS+=-lz
LDFLAGS+=-lasound
#LDFLAGS+=-fsanitize=address #Remove for production
#LDFLAGS+=-static-libasan #Remove for production

INCLUDES+=-I./
INCLUDES+=-Ilinux
INCLUDES+=-Iffmpeg_compiled/usr/local/include/
INCLUDES+=-I /usr/include/dbus-1.0
INCLUDES+=-I /usr/lib/arm-linux-gnueabihf/dbus-1.0/include
INCLUDES+=-I/usr/include/freetype2
INCLUDES+=-isystem$(SDKSTAGE)/opt/vc/include
INCLUDES+=-isystem$(SDKSTAGE)/opt/vc/include/interface/vcos/pthreads

DIST ?= omxplayer-dist
STRIP ?= strip

SRC=	linux/XMemUtils.cpp \
		OMXPlayerSync.cpp \
		linux/OMXAlsa.cpp \
		utils/log.cpp \
		DynamicDll.cpp \
		utils/PCMRemap.cpp \
		utils/RegExp.cpp \
		OMXSubtitleTagSami.cpp \
		OMXOverlayCodecText.cpp \
		BitstreamConverter.cpp \
		linux/RBP.cpp \
		OMXThread.cpp \
		OMXReader.cpp \
		OMXStreamInfo.cpp \
		OMXAudioCodecOMX.cpp \
		OMXCore.cpp \
		OMXVideo.cpp \
		OMXAudio.cpp \
		OMXClock.cpp \
		File.cpp \
		OMXPlayerVideo.cpp \
		OMXPlayerAudio.cpp \
		OMXPlayerSubtitles.cpp \
		SubtitleRenderer.cpp \
		Unicode.cpp \
		Srt.cpp \
		KeyConfig.cpp \
		OMXControl.cpp \
		Keyboard.cpp \
		omxplayer.cpp \

OBJS+=$(filter %.o,$(SRC:.cpp=.o))

all: dist

%.o: %.cpp
	@rm -f $@ 
	$(CXX) $(CFLAGS) $(INCLUDES) -c $< -o $@ -Wno-deprecated-declarations

omxplayer.o: help.h keys.h

version:
	bash gen_version.sh > version.h 

omxplayer.bin: version $(OBJS)
	$(CXX) $(LDFLAGS) -o omxplayer.bin $(OBJS) -lvchiq_arm -lvchostif -lvcos -ldbus-1 -lrt -lpthread -lavutil -lavcodec -lavformat -lswscale -lswresample -lpcre
	$(STRIP) omxplayer.bin

help.h: README.md Makefile
	awk '/SYNOPSIS/{p=1;print;next} p&&/KEY BINDINGS/{p=0};p' $< \
	| sed -e '1,3 d' -e 's/^/"/' -e 's/$$/\\n"/' \
	> $@
keys.h: README.md Makefile
	awk '/KEY BINDINGS/{p=1;print;next} p&&/KEY CONFIG/{p=0};p' $< \
	| sed -e '1,3 d' -e 's/^/"/' -e 's/$$/\\n"/' \
	> $@

omxplayer.1: README.md
	sed -e '/DOWNLOADING/,/omxplayer-dist/ d; /DBUS/,$$ d' $< >MAN
	curl -F page=@MAN http://mantastic.herokuapp.com 2>/dev/null >$@

clean:
	for i in $(OBJS); do (if test -e "$$i"; then ( rm $$i ); fi ); done
	@rm -f omxplayer.old.log omxplayer.log
	@rm -f omxplayer.bin
	@rm -rf $(DIST)
	@rm -f omxplayer-dist.tar.gz

ffmpeg:
	@rm -rf ffmpeg
	make -f Makefile.ffmpeg
	make -f Makefile.ffmpeg install

dist: omxplayer.bin omxplayer.1
	mkdir -p $(DIST)/usr/lib/omxplayer
	mkdir -p $(DIST)/usr/bin
	mkdir -p $(DIST)/usr/share/doc/omxplayer
	mkdir -p $(DIST)/usr/share/man/man1
	cp omxplayer omxplayer.bin $(DIST)/usr/bin
	cp COPYING $(DIST)/usr/share/doc/omxplayer
	cp README.md $(DIST)/usr/share/doc/omxplayer/README
	cp omxplayer.1 $(DIST)/usr/share/man/man1
	cp -P ffmpeg_compiled/usr/local/lib/*.so* $(DIST)/usr/lib/omxplayer/
	cd $(DIST); tar -czf ../$(DIST).tgz *

install:
	cp -r $(DIST)/* /
	cp dbus-tcp-session.conf /usr/share/dbus-1/tcp-session.conf

uninstall:
	rm -rf /usr/bin/omxplayer
	rm -rf /usr/bin/omxplayer.bin
	rm -rf /usr/lib/omxplayer
	rm -rf /usr/share/doc/omxplayer
	rm -rf /usr/share/man/man1/omxplayer.1
