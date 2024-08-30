# http://cdtdoug.ca/2017/10/06/qnx-cmake-toolchain-file.html

set(CMAKE_SYSTEM_NAME QNX)

set(arch gcc_ntoarmv7le)
set(ntoarch armv7)
set(QNX_PROCESSOR armle-v7)

set(CMAKE_C_COMPILER $ENV{QNX_HOST}/usr/bin/nto${ntoarch}-gcc)
set(CMAKE_C_COMPILER_TARGET ${arch})

set(CMAKE_CXX_COMPILER $ENV{QNX_HOST}/usr/bin/nto${ntoarch}-g++)
set(CMAKE_CXX_COMPILER_TARGET ${arch})

set(CMAKE_ASM_COMPILER qcc -V${arch})
set(CMAKE_ASM_DEFINE_FLAG "-Wa,--defsym,")

set(CMAKE_RANLIB
    $ENV{QNX_HOST}/usr/bin/nto${ntoarch}-ranlib
    CACHE PATH "QNX ranlib Program" FORCE)
set(CMAKE_AR
    $ENV{QNX_HOST}/usr/bin/nto${ntoarch}-ar
    CACHE PATH "QNX qr Program" FORCE)

if(NOT DEFINED OPENSSL_ROOT_DIR)
  set(OPENSSL_ROOT_DIR $ENV{QNX_TARGET}/armle-v7/usr/lib)
endif()
