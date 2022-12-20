# Runtime analysis using Clang sanitization flags.

option(SWIFT_SANITIZE_ADDRESS "Enable address sanitizer." OFF)
option(SWIFT_SANITIZE_LEAK "Enable leak sanitizer." OFF)
option(SWIFT_SANITIZE_MEMORY "Enable memory sanitizer." OFF)
option(SWIFT_SANITIZE_THREAD "Enable thread sanitizer." OFF)
option(SWIFT_SANITIZE_UNDEFINED "Enable undefined behavior sanitizer." OFF)
option(SWIFT_SANITIZE_DATAFLOW "Enable dataflow sanitizer." OFF)
option(SWIFT_SANITIZE_DISABLE_SUPPRESSION "Disable suppression of checks." OFF)

if (SWIFT_SANITIZE_ADDRESS OR
    SWIFT_SANITIZE_LEAK OR
    SWIFT_SANITIZE_MEMORY OR
    SWIFT_SANITIZE_THREAD OR
    SWIFT_SANITIZE_UNDEFINED OR
    SWIFT_SANITIZE_DATAFLOW)
  set(_SWIFT_SANITIZE TRUE)
else ()
  set(_SWIFT_SANITIZE FALSE)
endif()


# Some of these options can't be used simultaneously.
#
if (SWIFT_SANITIZE_ADDRESS AND SWIFT_SANITIZE_MEMORY )
  message(WARNING "Can't -fsanitize address/memory simultaneously.")
endif ()
if (SWIFT_SANITIZE_MEMORY AND SWIFT_SANITIZE_THREAD )
  message(WARNING "Can't -fsanitize memory/thread simultaneously.")
endif ()
if (SWIFT_SANITIZE_ADDRESS AND SWIFT_SANITIZE_THREAD )
  message(WARNING "Can't -fsanitize address/thread simultaneously.")
endif ()
# Instantiate C/C++ and C++-specific flags.
#
set(SWIFT_SANITIZE_FLAGS "")
# Dispatch sanitizer options based on compiler.
#
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  # See http://clang.llvm.org/docs and
  # http://clang.llvm.org/docs/UsersManual.html#controlling-code-generation
  # for more details.
  set(SWIFT_SANITIZE_FLAGS  "-g -fno-omit-frame-pointer")
  if (SWIFT_SANITIZE_ADDRESS)
    message(STATUS "Enabling address sanitizer.")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=address")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fno-optimize-sibling-calls")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize-address-use-after-scope")
  elseif (SWIFT_SANITIZE_MEMORY)
    message(STATUS "Enabling memory sanitizer.")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=memory")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fno-optimize-sibling-calls")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize-memory-track-origins=2")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize-memory-use-after-dtor")
  elseif (SWIFT_SANITIZE_THREAD)
    message(STATUS "Enabling thread sanitizer.")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=thread")
  endif ()
  if (SWIFT_SANITIZE_LEAK)
    message(STATUS "Enabling leak sanitizer.")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=leak")
  endif ()
  if (SWIFT_SANITIZE_UNDEFINED)
    message(STATUS "Enabling undefined behavior sanitizer.")
    # The `vptr` sanitizer won't work with `-fno-rtti`.
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=undefined -fno-sanitize=vptr")
  endif ()

  if (_SWIFT_SANITIZE)
    # Suppression files are supported at build time only by clang, not GCC.
    if (NOT DEFINED SWIFT_SANITIZE_SUPPRESSION_FILE)
      if (EXISTS "${PROJECT_ROOT}/sanitizers.supp")
        set(SWIFT_SANITIZE_SUPPRESSION_FILE "${PROJECT_ROOT}/sanitizers.supp")
      endif()
    endif ()
  endif()

  # According to the clang docs, we have to pass this file at build
  # time; the sanitizers that support runtime suppression can only use
  # it for third-party code that's not been built with sanitizer support
  # (https://clang.llvm.org/docs/AddressSanitizer.html#suppressing-errors-in-recompiled-code-ignorelist).
  # We build all our code, including third-party libraries, so we cannot
  # simply pass a file in an environment variable
  # (https://clang.llvm.org/docs/AddressSanitizer.html#suppressing-reports-in-external-libraries).
  #
  # The docs for the sanitizers don't seem to be complete or maintained,
  # though, nor is behavior consistent between different sanitizers, so
  # this theory could all be wrong!
  #
  # TODO(@peddie): I'm not sure how to make all targets that use this
  # depend on the suppression file contents.
  if (_SWIFT_SANITIZE AND NOT SWIFT_SANITIZE_DISABLE_SUPPRESSION AND (DEFINED SWIFT_SANITIZE_SUPPRESSION_FILE))
    message(STATUS "Building with sanitizer ignore list ${SWIFT_SANITIZE_SUPPRESSION_FILE}")
    message("    Note that this file is NOT CORRECTLY TRACKED as a dependency; if you modify its contents, you will have to force recompilation some other way.")
    set(SWIFT_SANITIZE_FLAGS "${SWIFT_SANITIZE_FLAGS} -fsanitize-ignorelist=${SWIFT_SANITIZE_SUPPRESSION_FILE}")
  endif()
elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.8)
  # See: https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
  #
  # We seem to need `-fuse-ld=gold` on Travis.
  set(SWIFT_SANITIZE_FLAGS  "-g3 -fno-omit-frame-pointer")
  if (SWIFT_SANITIZE_ADDRESS)
    message(STATUS "Enabling address sanitizer.")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=address")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize-address-use-after-scope")
  elseif (SWIFT_SANITIZE_MEMORY)
    message(STATUS "Enabling memory sanitizer.")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=memory")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize-memory-track-origins=2")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize-memory-use-after-dtor")
  elseif (SWIFT_SANITIZE_THREAD)
    message(STATUS "Enabling thread sanitizer.")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=thread")
  elseif (SWIFT_SANITIZE_LEAK)
    message(STATUS "Enabling leak sanitizer.")
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=leak")
  endif ()
  if (SWIFT_SANITIZE_UNDEFINED)
    message(STATUS "Enabling undefined behavior sanitizer.")
    # TODO(@peddie): how can we pass `-fno-sanitize=vptr` only when
    # RTTI is disabled?  Albatross unit tests, for example, use RTTI.
    #
    # The `vptr` sanitizer won't work with `-fno-rtti`.
    set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize=undefined -fno-sanitize=vptr")
  endif ()

  if (_SWIFT_SANITIZE)
    if(DEFINED SWIFT_SANITIZE_SUPPRESSION_FILE)
      message(WARNING "You are compiling with GCC, which does not support masking of sanitizer issues via `-fsanitize-ignorelist=`.")
      message(WARNING "If you don't want the issues in ${SWIFT_SANITIZE_SUPPRESSION_FILE} to be flagged, please build with clang instead.")
    endif()
  endif()
else ()
  message(FATAL_ERROR "Oh noes! We don't support your compiler.")
endif ()

if (_SWIFT_SANITIZE)
  message(STATUS "Enabling runtime analysis sanitizers!")
  message("    Consider the appropriate runtime options for your sanitizer(s):")
  message("    https://github.com/google/sanitizers/wiki/AddressSanitizerFlags#run-time-flags")
  message("    https://github.com/google/sanitizers/wiki/SanitizerCommonFlags")
  message("    e.g.:  ASAN_OPTIONS=check_initialization_order=true:detect_stack_use_after_return=true:strict_string_checks=true:halt_on_error=false")
  message("    You may also specify SWIFT_SANITIZE_SUPPRESSION_FILE to mask known errors.")
  set(SWIFT_SANITIZE_FLAGS  "${SWIFT_SANITIZE_FLAGS} -fsanitize-recover=all")
endif ()

set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} ${SWIFT_SANITIZE_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SWIFT_SANITIZE_FLAGS}")
