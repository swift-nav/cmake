include(CheckCXXSourceCompiles)

function(check_cxx_double_is_iec559)
  check_cxx_source_compiles("#include <limits>
  int main() {
    return std::numeric_limits<double>::is_iec559 ? 1 : 0;
  }" IEC559_DOUBLE_SUPPORTED)

  if(IEC559_DOUBLE_SUPPORTED)
    message(STATUS "Compiler supports IEC 559 (IEEE 754) doubles.")
  else()
    message(FATAL_ERROR "Compiler does not support IEC 559 (IEEE 754) doubles.")
  endif()
endfunction()

