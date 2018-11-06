# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "WCS"
version = v"6.2.0"

# Collection of sources required to build WCS
sources = [
    "https://cache.julialang.org/ftp://ftp.atnf.csiro.au/pub/software/wcslib/wcslib-6.2.tar.bz2" =>
    "0bc037db498cbd8e17ecaedd72fad15d6810ae885793882d5736f746f64c0fb1",
    "./patches"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wcslib-*/
if [[ "${target}" == *mingw* ]]; then
    patch -p1 < $WORKSPACE/srcdir/configure-mingw.patch
    autoconf
    ./configure --prefix=$prefix --host=$target --disable-fortran --without-cfitsio --without-pgplot --disable-utils CFLAGS=-DNO_OLDNAMES
else
    ./configure --prefix=$prefix --host=$target --disable-fortran --without-cfitsio --without-pgplot --disable-utils
fi
make
make install
# On Windows, the shared library has to be in the bin/ directory.
# BinaryBuilder would automatically move there the libwcs.dll file only,
# but it's a symbolic link and would be a broken link after moving it.
if [[ "${target}" == *mingw* ]]; then
    mkdir -p ${prefix}/bin
    mv ${prefix}/lib/libwcs.dll* ${prefix}/bin
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libwcs", :libwcs)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
