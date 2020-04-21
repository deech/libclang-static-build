cmake_minimum_required(VERSION 3.13)
project(libclang-linux-static)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
set(LIBCLANG_EXAMPLES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/examples")

if(APPLE)
  set(LIBCLANG_PREBUILT_URL https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-x86_64-apple-darwin.tar.xz)
else()
  set(LIBCLANG_PREBUILT_URL https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz)
endif()
set(CLANG_SOURCES_URL https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang-10.0.0.src.tar.xz)
set(NCURSES_SOURCES_URL https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.2.tar.gz)
if(APPLE)
  set(Z3_PREBUILT_URL https://github.com/Z3Prover/z3/releases/download/z3-4.8.7/z3-4.8.7-x64-osx-10.14.6.zip)
else()
  set(Z3_PREBUILT_URL https://github.com/Z3Prover/z3/releases/download/z3-4.8.7/z3-4.8.7-x64-ubuntu-16.04.zip)
endif()

include(Download)
message(STATUS "Downloading ncurses sources, prebuilt z3 & prebuilt libclang with sources; this is ~500MB, please be patient ...")
set(NCURSES_SOURCE_DIR)
download(ncurses_sources ${NCURSES_SOURCES_URL} NCURSES_DOWNLOAD_DIR)
set(LIBCLANG_SOURCES_DIR)
download(clang_sources ${CLANG_SOURCES_URL} LIBCLANG_SOURCES_DIR)
set(Z3_PREBUILT_DIR)
download(z3_prebuilt ${Z3_PREBUILT_URL} Z3_PREBUILT_DIR)
set(LIBCLANG_PREBUILT_DIR)
download(libclang_prebuilt ${LIBCLANG_PREBUILT_URL} LIBCLANG_PREBUILT_DIR)

include(ExternalProject)
ExternalProject_Add(ncurses
  SOURCE_DIR ${NCURSES_DOWNLOAD_DIR}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --enable-rpath --prefix=${CMAKE_INSTALL_PREFIX} --with-shared --with-static --with-normal --without-debug --without-ada --enable-widec --disable-pc-files --with-cxx-binding --without-cxx-shared --with-abi-version=5
  BUILD_COMMAND make
  INSTALL_COMMAND ""
  )

list(APPEND CMAKE_MODULE_PATH "${LIBCLANG_PREBUILT_DIR}/lib/cmake/clang")
list(APPEND CMAKE_MODULE_PATH "${LIBCLANG_PREBUILT_DIR}/lib/cmake/llvm")
list(APPEND CMAKE_MODULE_PATH "${LIBCLANG_SOURCES_DIR}/cmake/modules")
include(LibClangBuild)
include(HandleLLVMOptions)
include(AddLLVM)
include(AddClang)
include(ARBundle)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

get_libclang_sources_and_headers(
  ${LIBCLANG_SOURCES_DIR}
  ${LIBCLANG_PREBUILT_DIR}
  LIBCLANG_SOURCES
  LIBCLANG_ADDITIONAL_HEADERS
  LIBCLANG_PREBUILT_LIBS
  )

include_directories(${LIBCLANG_PREBUILT_DIR}/include)
add_clang_library(libclang_static
  STATIC
  DEPENDS ncurses
  OUTPUT_NAME clang_static
  ${LIBCLANG_SOURCES}
  ADDITIONAL_HEADERS ${LIBCLANG_ADDITIONAL_HEADERS}
  )
ExternalProject_Get_Property(ncurses BINARY_DIR)
set(NCURSES_BINARY_DIR ${BINARY_DIR})
if(APPLE)
  set(NCURSES_SHARED_LIB ${NCURSES_BINARY_DIR}/lib/libncursesw.dylib ${NCURSES_BINARY_DIR}/lib/libncursesw.5.dylib)
else()
  set(NCURSES_SHARED_LIB ${NCURSES_BINARY_DIR}/lib/libncursesw.so ${NCURSES_BINARY_DIR}/lib/libncursesw.so.5 ${NCURSES_BINARY_DIR}/lib/libncursesw.so.5.9)
endif()
unset(BINARY_DIR)
if(APPLE)
  set(Z3_SHARED_LIB ${Z3_PREBUILT_DIR}/bin/libz3.dylib)
else()
  set(Z3_SHARED_LIB ${Z3_PREBUILT_DIR}/bin/libz3.so)
endif()
add_clang_library(libclang_shared
  SHARED
  DEPENDS ncurses
  OUTPUT_NAME clang_shared
  ${LIBCLANG_SOURCES}
  ADDITIONAL_HEADERS ${LIBCLANG_ADDITIONAL_HEADERS}
  LINK_LIBS
  ${LIBCLANG_PREBUILT_LIBS}
  ${NCURSES_SHARED_LIB}
  dl
  pthread
  z
  LINK_COMPONENTS ${LLVM_TARGETS_TO_BUILD}
  )
set_target_properties(libclang_shared PROPERTIES VERSION 10)

arBundle("libclang_static_bundled.a"
  ${CMAKE_CURRENT_BINARY_DIR}/libclang_static.a
  ${LIBCLANG_PREBUILT_LIBS}
  ${NCURSES_BINARY_DIR}/lib/libncursesw.a
  ${Z3_PREBUILT_DIR}/bin/libz3.a
  )

if(APPLE)
  set(AR_COMMAND ${LIBCLANG_PREBUILT_DIR}/bin/llvm-ar -M  <${CMAKE_CURRENT_BINARY_DIR}/bundle.mri)
else()
  set(AR_COMMAND ${CMAKE_AR} -M <${CMAKE_CURRENT_BINARY_DIR}/bundle.mri)
endif()

add_custom_target(libclang_static_bundled ALL
  COMMAND ${AR_COMMAND}
  DEPENDS ncurses libclang_static libclang_shared
  BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/libclang_static_bundled.a
  )

set(MAKEFILE_LIBCLANG_INCLUDE ${CMAKE_INSTALL_PREFIX}/include)
if(APPLE)
  set(MAKEFILE_LIBCLANG_INCLUDE "${MAKEFILE_LIBCLANG_INCLUDE} -I${CMAKE_OSX_SYSROOT}/usr/include")
endif()
set(MAKEFILE_LIBCLANG_LIBDIR ${CMAKE_INSTALL_PREFIX}/lib)

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/examples/static)
if(APPLE)
  configure_file(${LIBCLANG_EXAMPLES}/Makefile_static_macos.in ${CMAKE_CURRENT_BINARY_DIR}/examples/static/Makefile)
  configure_file(${LIBCLANG_EXAMPLES}/Makefile_shared_macos.in ${CMAKE_CURRENT_BINARY_DIR}/examples/shared/Makefile)
else()
  configure_file(${LIBCLANG_EXAMPLES}/Makefile_static.in ${CMAKE_CURRENT_BINARY_DIR}/examples/static/Makefile)
  configure_file(${LIBCLANG_EXAMPLES}/Makefile_shared.in ${CMAKE_CURRENT_BINARY_DIR}/examples/shared/Makefile)
endif()
file(COPY ${LIBCLANG_EXAMPLES}/clang_visitor.c DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/examples/static)
file(COPY ${LIBCLANG_EXAMPLES}/sample.H DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/examples/static)
file(COPY ${LIBCLANG_EXAMPLES}/clang_visitor.c DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/examples/shared)
file(COPY ${LIBCLANG_EXAMPLES}/sample.H DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/examples/shared)

set(LIBCLANG_INSTALL_LIBS
  ${CMAKE_CURRENT_BINARY_DIR}/libclang_static_bundled.a
  ${Z3_PREBUILT_DIR}/bin/libz3.a
  ${Z3_SHARED_LIB}
  ${NCURSES_BINARY_DIR}/lib/libncursesw.a
  ${NCURSES_SHARED_LIB}
  )

install(PROGRAMS ${LIBCLANG_INSTALL_LIBS} DESTINATION lib)
install(DIRECTORY ${LIBCLANG_PREBUILT_DIR}/include/clang-c DESTINATION include)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/examples DESTINATION share/doc)
