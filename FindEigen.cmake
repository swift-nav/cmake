if(TARGET eigen)
  return()
endif()

add_library(eigen INTERFACE)

# Include Eigen library as system headers to suppress warnings when not
# cross-compiling. GNU ARM toolchain wraps system headers with `extern "C"`,
# causing errors, so in this case Eigen must be #included using
# `#pragma GCC system_header` in the source.
# See https://gcc.gnu.org/onlinedocs/cpp/System-Headers.html
if (NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  target_include_directories(eigen SYSTEM INTERFACE
      ${PROJECT_SOURCE_DIR}/third_party/eigen/)
else()
  target_include_directories(eigen INTERFACE
      ${PROJECT_SOURCE_DIR}/third_party/eigen/)
endif()

