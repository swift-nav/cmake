include(CheckCXXSourceCompiles)

# Checks if libc++ is being used
#
function(check_libcpp success)
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
  " ${success})
endfunction()
