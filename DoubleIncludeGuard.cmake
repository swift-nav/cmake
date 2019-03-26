function(DoubleIncludeGuard)
  set(optional FATAL)
  set(singleArgument NAME)

  cmake_parse_arguments(DoubleIncludeGuard "${optional}" "${singleArgument}" "" ${ARGV})

  if(NOT DoubleIncludeGuard_NAME)
    message(FATAL_ERROR "Must specify a unique name to protect")
    return()
  endif()

  if(GuardedIncludes_${DoubleIncludeGuard_NAME})
    if(DoubleIncludeGuard_FATAL)
      message(FATAL_ERROR "Name ${DoubleIncludeGuard_NAME} already defined")
    else()
      message(WARNING "Name ${DoubleIncludeGuard_NAME} already defined")
      set(DoubleIncludeGuard_FOUND TRUE PARENT_SCOPE)
    endif()
    return()
  endif()

  set(GuardedIncludes_${DoubleIncludeGuard_NAME} TRUE CACHE INTERNAL "${DoubleIncludeGuard_NAME} is protected against double inclusion")

endfunction()
  
