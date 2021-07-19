if(TARGET check-attributes)
  return()
endif()

add_custom_target(check-attributes ALL
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/scripts/check_attributes.sh
  WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  )
