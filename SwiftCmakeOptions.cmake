if(NOT PROJECT_NAME)
  message(FATAL_ERROR "Must define a project before trying to define options")
endif()

option(${PROJECT_NAME}_BUILD_TESTS "Enable build of unit tests for ${PROJECT_NAME}" ON)
option(${PROJECT_NAME}_BUILD_DOCS "Enable building of documentation for ${PROJECT_NAME}" ON)
option(${PROJECT_NAME}_BUILD_EXAMPLES "Enable building of example code for ${PROJECT_NAME}" ON)

  
