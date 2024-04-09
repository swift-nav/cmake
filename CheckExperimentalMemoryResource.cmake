include(CheckCXXSourceCompiles)

# The libc++ implementation that ships with clang < v16 still
# has the memory_resource header under experimental.
#
# This functions checks if we are using such a standard library
# implementation.
#
function(check_experimental_memory_resource success)
  check_cxx_source_compiles("
#include <experimental/memory_resource>
  int main() {
    return 0;
  }
  " ${success})
endfunction()
