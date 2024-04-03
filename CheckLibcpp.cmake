include(CheckCXXSourceCompiles)

# libc++ is more agressive about actually removing language features
# from the standard library than GNU.
#
# This function checks if libc++ is being used and sets a variable
# that should be added to the targets compile definitions if it does
# use these removed features.
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
