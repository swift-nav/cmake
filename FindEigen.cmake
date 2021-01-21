if(TARGET eigen)
  return()
endif()

add_library(eigen INTERFACE)

  target_include_directories(eigen SYSTEM INTERFACE
      ${PROJECT_SOURCE_DIR}/third_party/eigen/)

