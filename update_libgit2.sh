#!/bin/sh

#git submodule update --init
pushd libgit2
mkdir -p build
cd build
rm -f libgit2.a
cmake .. -DBUILD_SHARED_LIBS=OFF -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
cmake --build .
popd
