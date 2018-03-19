FROM ubuntu:16.04 AS build

RUN apt-get update \
&&  apt-get install -y --no-install-recommends \
    build-essential wget ca-certificates zlib1g zlib1g-dev \
    file autotools-dev autoconf automake \
&&  rm -rf /var/lib/apt/lists/* 

RUN mkdir -p /tmp \
&&  wget http://fr.mirror.babylon.network/gcc/releases/gcc-7.3.0/gcc-7.3.0.tar.gz -P /tmp \
&&  wget ftp://sourceware.org/pub/newlib/newlib-3.0.0.tar.gz -P /tmp \
&&  wget https://ftp.gnu.org/gnu/binutils/binutils-2.30.tar.gz -P /tmp \
&&  wget https://github.com/devkitPro/gba-tools/archive/v1.1.0.tar.gz -P /tmp \
&&  mkdir -p /tmp/binutils-{gcc, newlib, binutils} 

COPY gcc-7.3.0.patch /tmp
COPY newlib-3.0.0.patch /tmp

WORKDIR /tmp/build-binutils 
RUN tar zxvf ../binutils-2.30.tar.gz \
&& ./binutils-2.30/configure --prefix=/opt/devkitAGB --target=arm-none-eabi \
    --disable-nls --disable-werror --enable-lto --enable-plugins --enable-poison-system-directories \
&&  make \
&&  make install

ENV PATH="/opt/devkitAGB/bin:${PATH}"

WORKDIR /tmp/build-gcc
RUN tar zxvf ../gcc-7.3.0.tar.gz \
&&  patch -p1 -d gcc-7.3.0 -i /tmp/gcc-7.3.0.patch

WORKDIR /tmp/build-gcc/gcc-7.3.0
RUN ./contrib/download_prerequisites

WORKDIR /tmp/build-gcc
RUN set -ex \
&&  CFLAGS="-O2 -ffunction-sections -fdata-sections" CXXFLAGS="-O2 -ffunction-sections -fdata-sections"  \
    ./gcc-7.3.0/configure --enable-languages=c,c++ --with-gnu-as --with-gnu-ld --with-gcc --with-march=armv4t \
    --enable-cxx-flags='-ffunction-sections' --disable-libstdcxx-verbose --enable-interwork --enable-multilib \ 
    --disable-thread --disable-win32-registry --disable-nls --disable-debug --disable-libmudflap --disable-libssp \ 
    --disable-libgomp --disable-libstdcxx-pch --target=arm-none-eabi --with-newlib --without-headers --with-sysroot \
    --prefix=/opt/devkitAGB --enable-lto --with-system-zlib --disable-shared \
&&  make all-gcc -j4 \
&&  make install-gcc

ENV PATH="/opt/devkitAGB/bin:${PATH}"

WORKDIR /tmp/build-newlib
RUN tar zxvf ../newlib-3.0.0.tar.gz \
&&  patch -p1 -d newlib-3.0.0 -i /tmp/newlib-3.0.0.patch \
&&  CFLAGS="-O2 -ffunction-sections -fdata-sections" ./newlib-3.0.0/configure \
    --disable-newlib-supplied-syscalls --enable-newlib-mb --disable-newlib-wide-orient \
    --target=arm-none-eabi --prefix=/opt/devkitAGB \
&&  make -j4 \
&&  make install

WORKDIR /tmp/build-gcc
RUN make all -j4 \
&&  make install

WORKDIR /tmp
RUN tar zxvf v1.1.0.tar.gz \
&&  cd gba-tools-1.1.0 \
&&  ./autogen.sh \
&&  ./configure --prefix=/opt/devkitAGB \
&&  make -j4 \
&&  make install

COPY gba.ld /opt/devkitAGB/arm-none-eabi/lib
COPY gba.specs /opt/devkitAGB/arm-none-eabi/lib
COPY gba_crt0.s /opt/devkitAGB/arm-none-eabi/lib

RUN arm-none-eabi-as /opt/devkitAGB/arm-none-eabi/lib/gba_crt0.s -o /opt/devkitAGB/arm-none-eabi/lib/gba_crt0.o

COPY strip.sh /tmp
RUN chmod +x /tmp/strip.sh \
&&  bash /tmp/strip.sh

FROM debian:stretch
COPY --from=build /opt/devkitAGB /opt/devkitAGB
ENV PATH="/opt/devkitAGB/bin:${PATH}"