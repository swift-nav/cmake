find_package(Valgrind REQUIRED)

if(NOT VALGRIND_FOUND)
  message(WARNING "Unable to generate valgrind checks for target \"${target}\" due to missing valgrind package")
  return()
endif()

add_custom_target(valgrind_all
  COMMAND valgrind --tool=memcheck)
