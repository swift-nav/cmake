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
function(check_libcpp result)
  check_cxx_source_compiles("
  #include <iostream>
  int a =
  #ifdef _LIBCPP_VERSION
    1;
  #else
    kdfasfdl
  #endif
  int main() {
    return 0;
  }
  " success)

  if(success)
    set(${result} -D_LIBCPP_ENABLE_CXX20_REMOVED_FEATURES PARENT_SCOPE)
  endif()
endfunction()
