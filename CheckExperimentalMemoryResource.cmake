include(CheckCXXSourceCompiles)

# Some toolchains require explicitly linking against libatomic
#
# If such linking is required, then this function sets the
# value of result to "atomic". Otherwise it remains untouched.
# This makes it so that the function only needs to be called once
# per project.
#
# It can be used as follows:
#
# check_cxx_needs_atomic(LINK_ATOMIC)
# target_link_libraries(foo PRIVATE ${LINK_ATOMIC})
# ...
# target_link_libraries(bar PRIVATE ${LINK_ATOMIC})
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
