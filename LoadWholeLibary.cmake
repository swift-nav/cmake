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

# CMake script for forcing entrire contents of library to be included
#
# --whole-archive is not supported on MacOS and instead -force_load is used
# The function get_whole_archived_target returns WRAPPED_LIB as the IN_LIB
# with the appropriate flags.

function(get_whole_archived_target IN_LIB WRAPPED_LIB)
    include(CheckCSourceCompiles)
    set(CMAKE_REQUIRED_LIBRARIES "-Wl,--whole-archive;-Wl,--no-whole-archive")
        check_c_source_compiles("int main() { return 0; }" COMPILER_SUPPORTS_WHOLE_ARCHIVE)
    if (${COMPILER_SUPPORTS_WHOLE_ARCHIVE})
        set (${WRAPPED_LIB} "-Wl,--whole-archive;${IN_LIB};-Wl,--no-whole-archive" PARENT_SCOPE) 
    else()
        set (${WRAPPED_LIB} "-Wl,-force_load;${IN_LIB}" PARENT_SCOPE)
    endif()
endfunction()
