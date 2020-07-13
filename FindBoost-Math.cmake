if(TARGET boost-math)
  return()
endif()

add_library(boost-math INTERFACE)

if (DEFINED THIRD_PARTY_INCLUDES_AS_SYSTEM AND NOT THIRD_PARTY_INCLUDES_AS_SYSTEM)
  target_include_directories(boost-math INTERFACE
      ${PROJECT_SOURCE_DIR}/third_party/boost-math/include/)
else()
  target_include_directories(boost-math SYSTEM INTERFACE
      ${PROJECT_SOURCE_DIR}/third_party/boost-math/include/)
endif()