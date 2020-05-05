

function(swift_add_valgrind target)
  find_package(valgrind REQUIRED)

  if(NOT VALGRIND_FOUND)
    message(WARNING "Unable to generate valgrind checks for target \"${target}\" due to missing valgrind package")
    return()
  endif()

endfunction()
