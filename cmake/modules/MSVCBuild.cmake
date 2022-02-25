set(LIBCLANG_PREBUILT_URL https://ziglang.org/deps/llvm+clang+lld-13.0.0-x86_64-windows-msvc-release-mt.tar.xz)
set(CLANG_SOURCES_URL https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.0/clang-13.0.0.src.tar.xz)

include(Download)
message(STATUS "Downloading prebuilt libclang with sources; this is ~500MB, please be patient, 'libclang_prebuilt' will take several minutes ...")
download(clang_sources ${CLANG_SOURCES_URL} LIBCLANG_SOURCES_DIR)
download(libclang_prebuilt ${LIBCLANG_PREBUILT_URL} LIBCLANG_PREBUILT_DIR)

list(APPEND CMAKE_MODULE_PATH "${LIBCLANG_PREBUILT_DIR}/lib/cmake/clang")
list(APPEND CMAKE_MODULE_PATH "${LIBCLANG_PREBUILT_DIR}/lib/cmake/llvm")
list(APPEND CMAKE_MODULE_PATH "${LIBCLANG_SOURCES_DIR}/cmake/modules")

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
include(LibClangBuild)
include(HandleLLVMOptions)
include(AddLLVM)
include(AddClang)

get_libclang_sources_and_headers(
  ${LIBCLANG_SOURCES_DIR}
  ${LIBCLANG_PREBUILT_DIR}
  LIBCLANG_SOURCES
  LIBCLANG_ADDITIONAL_HEADERS
  LIBCLANG_PREBUILT_LIBS
  )
include_directories(${LIBCLANG_PREBUILT_DIR}/include)
add_clang_library(libclang
  SHARED
  STATIC
  OUTPUT_NAME clang
  ${LIBCLANG_SOURCES}
  LINK_LIBS ${LIBCLANG_PREBUILT_LIBS} Version
  ADDITIONAL_HEADERS ${LIBCLANG_ADDITIONAL_HEADERS}
  )

set_target_properties(libclang PROPERTIES VERSION 12)

target_compile_definitions(obj.libclang PUBLIC "_CINDEX_LIB_")

find_program(lib_tool lib)
if(NOT lib_tool)
  get_filename_component(CXX_COMPILER_DIRECTORY "${CMAKE_CXX_COMPILER}" PATH)
  set(lib_tool "${CXX_COMPILER_DIRECTORY}/lib.exe")
endif()
set(AR_COMMAND ${lib_tool} /NOLOGO /OUT:${CMAKE_CURRENT_BINARY_DIR}/clang_static_bundled.lib "${CMAKE_CURRENT_BINARY_DIR}/obj.libclang.dir/Release/obj.libclang.lib" ${LIBCLANG_PREBUILT_LIBS})

add_custom_target(libclang_static_bundled ALL
  COMMAND ${AR_COMMAND}
  DEPENDS libclang
  BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/clang_static_bundled.lib
  )
set(LIBCLANG_INSTALL_LIBS ${CMAKE_CURRENT_BINARY_DIR}/clang_static_bundled.lib)

set(CMAKE_MSVC_LIB_DIR ${CMAKE_INSTALL_PREFIX}/lib)
set(CMAKE_MSVC_INCLUDE_DIR ${CMAKE_INSTALL_PREFIX}/include)
configure_file(${LIBCLANG_EXAMPLES}/CMakeLists.MSVC.in ${CMAKE_CURRENT_BINARY_DIR}/examples/static/CMakeLists.txt)
file(COPY ${LIBCLANG_EXAMPLES}/sample.H DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/examples/static/bin)
file(COPY ${LIBCLANG_EXAMPLES}/clang_visitor.c DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/examples/static)
file(COPY ${LIBCLANG_EXAMPLES}/README.txt DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/examples/static)

install(PROGRAMS ${LIBCLANG_INSTALL_LIBS} DESTINATION lib)
install(DIRECTORY ${LIBCLANG_PREBUILT_DIR}/include/clang-c DESTINATION include)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/examples DESTINATION share/doc)
