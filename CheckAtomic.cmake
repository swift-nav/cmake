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
function(check_cxx_needs_atomic result)
  check_cxx_source_compiles("
#include <atomic>
#include <cstdint>
  int main() {
    return std::atomic<uint64_t>(0).load();
  }
  " success)

  if(NOT success)
    set(${result} atomic PARENT_SCOPE)
  endif()
endfunction()
