if(TARGET eigen)
  return()
endif()

add_library(eigen INTERFACE)

if (DEFINED THIRD_PARTY_INCLUDES_AS_SYSTEM AND NOT THIRD_PARTY_INCLUDES_AS_SYSTEM)
  target_include_directories(eigen INTERFACE
      ${PROJECT_SOURCE_DIR}/third_party/eigen/)
else()
  target_include_directories(eigen SYSTEM INTERFACE
      ${PROJECT_SOURCE_DIR}/third_party/eigen/)
endif()

