#
# Copyright (C) 2021 Swift Navigation Inc.
# Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must
# be be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

#
# OVERVIEW
#
# Provides functions that help generate Doxygen documentation for your project.
#
# The following functions are exposed for users to use:
#
#   swift_add_doxygen(target
#     [CONFIGURE_FILE file]
#     [OUTPUT_DIRECTORY directory]
#     [SOURCE_DIRECTORIES directories...]
#   )
#
# GENERATING DOCUMENTATION
#
# In order to create a cmake target that generates doxygen documentation, simply
# invoke the "swift_add_doxygen" function with a desired name for your target.
# The function offer the following options:
#
#   CONFIGURE_FILE: specify a Doxygen configuration file here, if one isn't
#   provided, the default values will be ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in.
#   The function will run the configuration file through cmake's "configure_file"
#   command, so any cmake variables can be injected into the file. There are a
#   few special variables available for use outside what is already available
#   within the user's scope.
#
#     DOXYGEN_CONFIGURE_FILE: path specified within the CONFIGURE_FILE option
#     DOXYGEN_OUTPUT_DIRECTORY: path specified within the OUTPUT_DIRECTORY option
#     DOXYGEN_SOURCE_DIRECTORIES: paths specified within the SOURCE_DIRECTORIES option
#     DOXYGEN_EXCLUDE: paths specified within the EXCLUDE option
#
#   Please note that whenever you wish to use the above variables within the
#   Doxygen configuration file, make sure they are surrounded by quotes, so for
#   example to specify the Doxygen value INPUT, you should do the following:
#
#     INPUT = "@DOXYGEN_SOURCE_DIRECTORIES@"
#
#   You could also use the ${VARIABLE} as well to specify variables, but would
#   suggest you use @VARIABLE@.
#
#   OUTPUT_DIRECTORY: specify the location where doxygen outputs are to be
#   generated. This variable will be exposed as DOXYGEN_OUTPUT_DIRECTORY and
#   should be assigned to the doxygen configuration file's OUTPUT_DIRECTORY
#   value for it to be useful. Default value is set to
#   "${CMAKE_CURRENT_BINARY_DIR}".
#
#   SOURCE_DIRECTORIES: specifies the directories which doxygen will look
#   through to extract the documentation from. This variable will be exposed
#   as DOXYGEN_SOURCE_DIRECTORIES and should be assigned to the doxygen
#   configuration file's INPUT variable for it to be useful. Default value is
#   set to "${CMAKE_CURRENT_SOURCE_DIR}".
#
#   EXCLUDE: specifies the files which doxygen will not look through to
#   extract the documentation from. This variable will be exposed
#   as DOXYGEN_EXCLUDE and should be assigned to the doxygen configuration
#   file's EXCLUDE variable for it to be useful. Default value is empty.
#

function(swift_add_doxygen target)
  find_package(Doxygen)

  if(NOT DOXYGEN_FOUND)
    message(WARNING "Unable to generate doxygen documentation for target \"${target}\" due to missing doxygen package")
    return()
  endif()

  set(argOptions)
  set(argSingleArguments CONFIGURE_FILE OUTPUT_DIRECTORY)
  set(argMultiArguments SOURCE_DIRECTORIES EXCLUDE)

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_doxygen unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(DOXYGEN_CONFIGURE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in)
  set(DOXYGEN_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  set(DOXYGEN_SOURCE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR})

  if(x_CONFIGURE_FILE)
    set(DOXYGEN_CONFIGURE_FILE ${x_CONFIGURE_FILE})
  endif()

  if(x_OUTPUT_DIRECTORY)
    set(DOXYGEN_OUTPUT_DIRECTORY ${x_OUTPUT_DIRECTORY})
  endif()

  if(x_SOURCE_DIRECTORIES)
    set(DOXYGEN_SOURCE_DIRECTORIES ${x_SOURCE_DIRECTORIES})
  endif()

  if(x_EXCLUDE)
    set(DOXYGEN_EXCLUDE ${x_EXCLUDE})
    string(REPLACE ";" "\" \"" DOXYGEN_EXCLUDE "${DOXYGEN_EXCLUDE}")
  endif()

  if(NOT DEFINED PLANTUML_JAR_PATH)
    set(PLANTUML_JAR_PATH /usr/local/bin/plantuml.jar)
  endif()

  string(REPLACE ";" "\" \"" DOXYGEN_SOURCE_DIRECTORIES "${DOXYGEN_SOURCE_DIRECTORIES}")

  configure_file(${DOXYGEN_CONFIGURE_FILE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)

  add_custom_target(${target}
    COMMAND
      ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
    DEPENDS
      ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
    COMMENT
      "Generating doxygen documentation output to \"${DOXYGEN_OUTPUT_DIRECTORY}\""
  )

endfunction()
