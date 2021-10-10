#!/bin/sh

# Courtesy of Marko Mäkelä
# Taken from MDEV-20377, version as of Oct 11, 2021

set -eux
: ${CLANG=13}
: ${MSAN_LIBDIR=..}
: ${PARALLEL=$(nproc)}

export CC=clang-$CLANG CXX=clang++-$CLANG
sudo apt-get install -y clang-$CLANG libc++-$CLANG-dev libc++abi-$CLANG-dev automake
sudo apt-get install -y libunwind8-dev
apt-get source llvm-toolchain-$CLANG libgnutls28-dev libnettle7 libidn2 libgmp10

cd llvm-toolchain-$CLANG-$CLANG.*/
mkdir libc++msan
cd libc++msan
cmake ../libcxx -DCMAKE_BUILD_TYPE=RelWithDebInfo -DLLVM_USE_SANITIZER=Memory
cmake --build . -- -j$PARALLEL
cd ../..

export CFLAGS="-fno-omit-frame-pointer -O2 -g -fsanitize=memory"
export CXXFLAGS="$CFLAGS"
export LDFLAGS=-fsanitize=memory

cd gnutls28-*/
aclocal
automake --add-missing
./configure --with-included-libtasn1 --with-included-unistring \
	    --without-p11-kit --disable-hardware-acceleration
make -j$PARALLEL
cd ..

cd nettle-*/
./configure --disable-assembler
make -j$PARALLEL
cd ..

cd libidn2-*/
./configure --enable-valgrind-tests=no
make -j$PARALLEL
cd ..

cd gmp-*/
./configure --disable-assembly
make -j$PARALLEL
cd ..

cp -aL llvm-toolchain-$CLANG-$CLANG*/libc++msan/lib/libc++.so* \
   gnutls28-*/lib/.libs/libgnutls.so* \
   nettle-*/.lib/lib*.so* \
   gmp-*/.libs/libgmp.so* \
   libidn2-*/lib/.libs/libidn2.so \
   "$MSAN_LIBDIR"
