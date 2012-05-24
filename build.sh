#!/bin/bash
#
# build.sh
# Copyright 2007 Alex Holkner
#
# This file is part of AVbin.
#
# AVbin is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version.
#
# AVbin is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

AVBIN_VERSION=`cat VERSION`
FFMPEG_REVISION=`cat ffmpeg.revision`

# Directory holding ffmpeg source code.
FFMPEG=ffmpeg

fail() {
    echo "AVbin: Fatal error: $1"
    exit 1
}

build_ffmpeg() {
    config=`pwd`/ffmpeg.configure.$PLATFORM
    common=`pwd`/ffmpeg.configure.common

    pushd $FFMPEG

    # If we're not rebuilding, then we need to configure FFmpeg
    if [ ! $REBUILD ]; then
        make distclean
        cat $config $common | egrep -v '^#' | xargs ./configure || exit 1
    fi

    # Actually build FFmpeg
    make || exit 1
    popd
}

build_avbin() {
    export AVBIN_VERSION
    export FFMPEG_REVISION
    export PLATFORM
    export FFMPEG
    if [ ! $REBUILD ]; then
        make clean
    fi
    make || exit 1
}

build_darwin_universal() {
    if [ ! -e dist/darwin-x86-32/libavbin.$AVBIN_VERSION.dylib ]; then
        PLATFORM=darwin-x86-32
        build_ffmpeg
        build_avbin
    fi

    if [ ! -e dist/darwin-x86-64/libavbin.$AVBIN_VERSION.dylib ]; then
        PLATFORM=darwin-x86-64
        build_ffmpeg
        build_avbin
    fi

    mkdir -p dist/darwin-universal
    lipo -create \
        -output dist/darwin-universal/libavbin.$AVBIN_VERSION.dylib \
        dist/darwin-x86-32/libavbin.$AVBIN_VERSION.dylib \
        dist/darwin-x86-64/libavbin.$AVBIN_VERSION.dylib
}

while [ "${1:0:2}" == "--" ]; do
    case $1 in
        "--help") # fall through
            ;;
        "--rebuild") REBUILD=1;;
        "--clean")
            pushd $FFMPEG
            make clean
            make distclean
            find . -name '*.d' -exec rm -f '{}' ';'
            find . -name '*.pc' -exec rm -f '{}' ';'
            rm -f config.log config.err config.h config.mak .config .version
            popd
            rm -rf dist
            rm -rf build
            exit
            ;;
        *)           echo "Unrecognised option: $1" && exit 1;;
    esac
    shift
done;

platforms=$*

if [ ! "$platforms" ]; then
    echo "Usage: ./build.sh [options] <platform> [<platform> [<platform> ...]]"
    echo
    echo "Options"
    echo "  --clean             Don't build, just clean up all generated files and directories."
    echo "  --rebuild           Don't reconfigure, just run make again."
    echo
    echo "Supported platforms:"
    echo "  linux-x86-32"
    echo "  linux-x86-64"
    echo "  darwin-x86-32"
    echo "  darwin-x86-64"
    echo "  darwin-universal (builds all supported darwin architectures into one library)"
    echo "  win32"
    echo "  win64"
    exit 1
fi

for PLATFORM in $platforms; do
    if [ $PLATFORM == "darwin-universal" ]; then
        build_darwin_universal
    else
        build_ffmpeg
        build_avbin
    fi
done
