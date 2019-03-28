macro(DoubleIncludeGuard TGTNAME)
  if(TARGET ${TGTNAME})
    message(WARNING "Target ${TGTNAME} already defined")
    return()
  endif()

endmacro(DoubleIncludeGuard)
  
