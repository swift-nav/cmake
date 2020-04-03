if(TARGET boost-math)
  return()
endif()

add_library(boost-math INTERFACE)

target_include_directories(boost-math SYSTEM INTERFACE
      ${PROJECT_SOURCE_DIR}/third_party/boost-math/include/)
