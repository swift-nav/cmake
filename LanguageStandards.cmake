#
# Offers a simple function to set a number of targets to follow the company
# wide C/C++ standard version. One can bypass some of these standards through
# the following options:
#
# Single Value Options:
#
#  C: C language standard to follow, current support values are 90, 99, and 11 (see: https://cmake.org/cmake/help/latest/prop_tgt/C_STANDARD.html)
#  CXX: C++ language standard to follow, current supported values are 98, 11, 14, 17, and 20 (see: https://cmake.org/cmake/help/latest/prop_tgt/CXX_STANDARD.html)
#
# Usage: set a target to conform to company standard
#
#   add_executable(target_name main.cpp)
#   swift_set_language_standards(target_name)
#
# Usage: specify your own standards (C++17 and C98) on multiple targets
#
#   add_library(library_target file1.c file2.cc)
#   add_executable(executable_target main.cpp)
#   target_link_libraries(executable_target PRIVATE library_target)
#
#   swift_set_language_standards(executable_target library_target
#     C 99
#     CXX 17
#   )
#

function(swift_set_language_standards)
    set(argOption "")
    set(argSingle "C" "CXX")
    set(argMulti "")

    cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

    if(NOT x_C)
        set(x_C 99)
    endif()

    if(NOT x_CXX)
        set(x_CXX 14)
    endif()

    set_target_properties(${x_UNPARSED_ARGUMENTS}
        PROPERTIES
            C_STANDARD ${x_C}
            C_STANDARD_REQUIRED ON
            C_EXTENSIONS ON
            CXX_STANDARD ${x_CXX}
            CXX_STANDARD_REQUIRED ON
            CXX_EXTENSIONS OFF
    )
endfunction()
