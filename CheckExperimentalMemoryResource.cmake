include(CheckCXXSourceCompiles)

# The libc++ implementation that ships with clang-14 still
# has the memory_resource header under experimental.
#
# This functions checks if we are using such a standard library
# implementation and sets a definition to be used if we need to
# include that version of the header.
#
function(check_experimental_memory_resource result)
  check_cxx_source_compiles("
#include <experimental/memory_resource>
  int main() {
    return 0;
  }
  " success)

  if(success)
    set(${result} -DSWIFTNAV_EXPERIMENTAL_MEMORY_RESOURCE PARENT_SCOPE)
  endif()
endfunction()
