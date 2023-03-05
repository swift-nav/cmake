#===============================================================================
# Copyright 2021-2022 Intel Corporation.
#
# This software and the related documents are Intel copyrighted  materials,  and
# your use of  them is  governed by the  express license  under which  they were
# provided to you (License).  Unless the License provides otherwise, you may not
# use, modify, copy, publish, distribute,  disclose or transmit this software or
# the related documents without Intel's prior written permission.
#
# This software and the related documents  are provided as  is,  with no express
# or implied  warranties,  other  than those  that are  expressly stated  in the
# License.
#===============================================================================

#===================================================================
# CMake Config file for Intel(R) oneAPI Math Kernel Library (oneMKL)
#===================================================================

#===============================================================================
# Input parameters
#=================
#-------------
# Main options
#-------------
# MKL_ROOT: oneMKL root directory (May be required for non-standard install locations. Optional otherwise.)
#    Default: use location from MKLROOT environment variable or <Full path to this file>/../../../ if MKLROOT is not defined
# MKL_ARCH
#    Values:  intel64
#    Default: intel64
# MKL_LINK
#    Values:  static
#    Default: static
# MKL_THREADING
#    Values:  gnu_thread (GNU OpenMP)
#    Default: gnu_thread
# MKL_INTERFACE (for MKL_ARCH=intel64 only)
#    Values:  lp64
#       GNU interface will be selected based on Compiler.
#    Default: lp64
#
#==================
# Output parameters
#==================
# MKL_ROOT
#     oneMKL root directory.
# MKL_INCLUDE
#     Use of target_include_directories() is recommended.
#     INTERFACE_INCLUDE_DIRECTORIES property is set on mkl_core and mkl_rt libraries.
#     Alternatively, this variable can be used directly (not recommended as per Modern CMake)
# MKL_ENV
#     Provides all environment variables based on input parameters.
#     Currently useful for mkl_rt linking and BLACS on Windows.
#     Must be set as an ENVIRONMENT property.
# Example:
#     add_test(NAME mytest COMMAND myexe)
#     if(MKL_ENV)
#       set_tests_properties(mytest PROPERTIES ENVIRONMENT "${MKL_ENV}")
#     endif()
#
# MKL::<library name>
#     IMPORTED targets to link MKL libraries individually or when using a custom link-line.
#     mkl_core and mkl_rt have INTERFACE_* properties set to them.
#     Please refer to Intel(R) oneMKL Link Line Advisor for help with linking.
#
# Below INTERFACE targets provide full link-lines for direct use.
# Example:
#     target_link_options(<my_linkable_target> PUBLIC $<LINK_ONLY:MKL::MKL>)
#
# MKL::MKL
#     Link line for C API
#===============================================================================

if(${CMAKE_VERSION} VERSION_LESS "3.13")
  message(FATAL_ERROR "The minimum supported CMake version is 3.13. You are running version ${CMAKE_VERSION}")
endif()

include_guard()
include(FindPackageHandleStandardArgs)

if(NOT MKL_LIBRARIES)

  # Set CMake policies for well-defined behavior across CMake versions
  cmake_policy(SET CMP0011 NEW)

  # ================
  # Compiler checks
  # ================

  if(CMAKE_C_COMPILER)
    get_filename_component(C_COMPILER_NAME ${CMAKE_C_COMPILER} NAME)
  endif()
  if(CMAKE_CXX_COMPILER)
    get_filename_component(CXX_COMPILER_NAME ${CMAKE_CXX_COMPILER} NAME)
  endif()

  if(C_COMPILER_NAME MATCHES "^clang")
    set(CLANG_COMPILER ON)
  elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    set(GNU_C_COMPILER ON)
  else()
    message(FATAL_ERROR "Only clang or gnu compilers supported.")
  endif()

  # ================
  # System-specific
  # ================

  # Extensions
  if(UNIX AND NOT APPLE)
    set(LIB_PREFIX "lib")
    set(LIB_EXT ".a")
  else()
    message(FATAL_ERROR "MKL support not available for architectures other than linux.")
  endif()

  # Set target system architecture
  set(MKL_ARCH intel64)

  # ==========
  # Setup MKL
  # ==========

  # Set MKL_ROOT directory
  if(NOT DEFINED MKL_ROOT)
    if(DEFINED ENV{MKLROOT})
      set(MKL_ROOT $ENV{MKLROOT})
    else()
      message(FATAL_ERROR "MKLROOT environment variable is not defined.")
    endif()
  endif()

  # Define MKL_LINK
  set(MKL_LINK static)
  set(MKL_INTERFACE "lp64")
  set(MKL_INTERFACE_FULL intel_${MKL_INTERFACE})

  # Define MKL headers
  find_path(
    MKL_H mkl.h
    HINTS ${MKL_ROOT}
    PATH_SUFFIXES include)
  list(APPEND MKL_INCLUDE ${MKL_H})

  set(MKL_THREADING gnu_thread)

  # Checkpoint - Verify if required options are defined
  find_package_handle_standard_args(MKL REQUIRED_VARS MKL_ROOT MKL_ARCH MKL_INCLUDE MKL_LINK MKL_THREADING MKL_INTERFACE_FULL)

  # Provides a list of IMPORTED targets for the project
  if(NOT DEFINED MKL_IMPORTED_TARGETS)
    set(MKL_IMPORTED_TARGETS "")
  endif()

  # Clear temporary variables
  set(MKL_C_COPT "")
  set(MKL_CXX_COPT "")

  set(MKL_SUPP_LINK "") # Other link options. Usually at the end of the link-line.
  set(MKL_LINK_LINE) # For MPI only
  set(MKL_ENV_PATH "") # Temporary variable to work with PATH
  set(MKL_ENV "") # Exported environment variables

  # Modify PATH variable to make it CMake-friendly
  set(OLD_PATH $ENV{PATH})
  string(REPLACE ";" "\;" OLD_PATH "${OLD_PATH}")

  # Compiler options
  if(GNU_C_COMPILER)
    list(APPEND MKL_C_COPT -m64)
  endif()

  set(MKL_IFACE_LIB mkl_${MKL_INTERFACE_FULL})
  set(MKL_CORE mkl_core)
  set(MKL_THREAD mkl_${MKL_THREADING})

  set(START_GROUP "-Wl,--start-group")
  set(END_GROUP "-Wl,--end-group")

  # Create a list of requested libraries, based on input options (MKL_LIBRARIES) Create full link-line in MKL_LINK_LINE
  list(APPEND MKL_LINK_LINE ${START_GROUP})
  list(APPEND MKL_LIBRARIES ${MKL_IFACE_LIB} ${MKL_THREAD} ${MKL_CORE})
  list(APPEND MKL_LINK_LINE MKL::${MKL_IFACE_LIB} MKL::${MKL_THREAD} MKL::${MKL_CORE})
  list(APPEND MKL_LINK_LINE ${END_GROUP})

  # Find all requested libraries
  foreach(lib ${MKL_LIBRARIES})
    unset(${lib}_file CACHE)
    find_library(
      ${lib}_file ${LIB_PREFIX}${lib}${LIB_EXT}
      PATHS ${MKL_ROOT}
      PATH_SUFFIXES "lib" "lib/${MKL_ARCH}")
    add_library(MKL::${lib} STATIC IMPORTED)
    find_package_handle_standard_args(MKL REQUIRED_VARS ${lib}_file)
    # CMP0111, implemented in CMake 3.20+ requires a shared library target on Windows to be defined with IMPLIB and LOCATION property. It also requires a static library target to
    # be defined with LOCATION property. Setting the policy to OLD usage, using cmake_policy() does not work as of 3.20.0, hence the if-else below.
    set_target_properties(MKL::${lib} PROPERTIES IMPORTED_LOCATION "${${lib}_file}")
    list(APPEND MKL_IMPORTED_TARGETS MKL::${lib})
  endforeach()

  # Threading selection
  list(APPEND MKL_SUPP_LINK -lgomp -fopenmp)
  list(APPEND MKL_SUPP_LINK -lm -ldl -lpthread)

  # Setup link types based on input options
  set(LINK_TYPES "")

  # Single target for all C, Fortran link-lines
  add_library(MKL::MKL INTERFACE IMPORTED GLOBAL)
  target_compile_options(
    MKL::MKL INTERFACE $<$<STREQUAL:$<TARGET_PROPERTY:LINKER_LANGUAGE>,C>:${MKL_C_COPT}>
                       $<$<STREQUAL:$<TARGET_PROPERTY:LINKER_LANGUAGE>,CXX>:${MKL_CXX_COPT}>)
  target_link_libraries(MKL::MKL INTERFACE ${MKL_LINK_LINE} ${MKL_THREAD_LIB} ${MKL_SUPP_LINK})
  list(APPEND LINK_TYPES MKL::MKL)

  foreach(link ${LINK_TYPES})
    # Set properties on all INTERFACE targets
    target_include_directories(${link} BEFORE INTERFACE "${MKL_INCLUDE}")
    list(APPEND MKL_IMPORTED_TARGETS ${link})
  endforeach(link) # LINK_TYPES

  if(MKL_ENV_PATH)
    list(APPEND MKL_ENV "PATH=${MKL_ENV_PATH}\;${OLD_PATH}")
  endif()

endif() # MKL_LIBRARIES
