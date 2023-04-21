# ===============================================================================
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
# ===============================================================================

# ===================================================================
# CMake Config file for Intel(R) oneAPI Math Kernel Library (oneMKL)
# ===================================================================

# ===============================================================================
# Input parameters
# =================
# MKL_ROOT: oneMKL root directory (May be required for non-standard install
#           locations. Optional otherwise.)
#    Default: use location from MKLROOT environment variable
#             or "/opt/intel/oneapi/mkl/latest" if MKLROOT is not defined
# ==================
# Output parameters
# ==================
# MKL_ROOT oneMKL root directory. MKL::MKL Link line for C API
# ===============================================================================

if(TARGET MKL::MKL)
  message(STATUS "MKL::MKL target has already been loaded.")
  set(MKL_FOUND TRUE)
  return()
endif()

if(${CMAKE_VERSION} VERSION_LESS "3.13")
  message(FATAL_ERROR "The minimum supported CMake version is 3.13. You are running version ${CMAKE_VERSION}")
endif()

include(FindPackageHandleStandardArgs)

if(NOT MKL_LIBRARIES)

  # Set CMake policies for well-defined behavior across CMake versions
  cmake_policy(SET CMP0011 NEW)

  # ================
  # Compiler checks
  # ================

  include(CMakeDetermineCCompiler)
  if(CMAKE_C_COMPILER)
    get_filename_component(C_COMPILER_NAME ${CMAKE_C_COMPILER} NAME)
  endif()
  if(CMAKE_CXX_COMPILER)
    get_filename_component(CXX_COMPILER_NAME ${CMAKE_CXX_COMPILER} NAME)
  endif()

  if(NOT
     ((C_COMPILER_NAME MATCHES "^clang")
      OR (CMAKE_C_COMPILER_ID STREQUAL "GNU")
      OR (CXX_COMPILER_NAME MATCHES "^clang")
      OR (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")))
    message(FATAL_ERROR "Only clang or gnu compilers supported. Name=${C_COMPILER_NAME} - Id=${CMAKE_C_COMPILER_ID}")
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

  # ==========
  # Setup MKL
  # ==========

  # Set MKL_ROOT directory
  set(MKLROOT_DEFAULT "/opt/intel/oneapi/mkl/latest")
  if(NOT DEFINED MKL_ROOT)
    if(DEFINED ENV{MKLROOT})
      set(MKL_ROOT $ENV{MKLROOT})
    elseif(EXISTS ${MKLROOT_DEFAULT})
      set(MKL_ROOT ${MKLROOT_DEFAULT})
    else()
      message(FATAL_ERROR "MKLROOT environment variable is not defined.")
    endif()
  endif()

  set(MKL_INCLUDE "${MKL_ROOT}/include")

  # Define MKL headers
  find_path(
    MKL_H mkl.h
    HINTS ${MKL_ROOT}
    PATH_SUFFIXES include)
  list(APPEND MKL_INCLUDE ${MKL_H})

  # Checkpoint - Verify if required options are defined
  find_package_handle_standard_args(MKL REQUIRED_VARS MKL_ROOT MKL_INCLUDE)

  # Create a list of requested libraries, based on input options (MKL_LIBRARIES) Create full link-line in MKL_LINK_LINE
  set(MKL_LINK_LINE "")
  set(MKL_LIBRARIES "")
  set(MKL_SUPP_LINK "")
  list(APPEND MKL_LINK_LINE "-Wl,--start-group" MKL::mkl_intel_lp64 MKL::mkl_gnu_thread MKL::mkl_core "-Wl,--end-group")
  list(APPEND MKL_LIBRARIES mkl_intel_lp64 mkl_gnu_thread mkl_core)
  list(APPEND MKL_SUPP_LINK -lgomp -fopenmp -lm -ldl -lpthread)

  set(MKL_IMPORTED_TARGETS "")

  # Find all requested libraries
  foreach(lib ${MKL_LIBRARIES})
    unset(${lib}_file CACHE)
    find_library(
      ${lib}_file ${LIB_PREFIX}${lib}${LIB_EXT}
      PATHS ${MKL_ROOT}
      PATH_SUFFIXES "lib" "lib/intel64")
    add_library(MKL::${lib} STATIC IMPORTED)
    find_package_handle_standard_args(MKL REQUIRED_VARS ${lib}_file)
    # CMP0111, implemented in CMake 3.20+ requires a shared library target on Windows to be defined with IMPLIB and
    # LOCATION property. It also requires a static library target to be defined with LOCATION property. Setting
    # the policy to OLD usage, using cmake_policy() does not work as of 3.20.0, hence the if-else below.
    set_target_properties(MKL::${lib} PROPERTIES IMPORTED_LOCATION "${${lib}_file}")
    list(APPEND MKL_IMPORTED_TARGETS MKL::${lib})
  endforeach()

  # Single target for all C, Fortran link-lines
  add_library(MKL::MKL INTERFACE IMPORTED GLOBAL)
  target_compile_options(MKL::MKL INTERFACE -m64)
  target_compile_definitions(MKL::MKL INTERFACE EIGEN_USE_MKL_ALL)
  target_link_libraries(MKL::MKL INTERFACE ${MKL_LINK_LINE} ${MKL_SUPP_LINK})
  target_include_directories(MKL::MKL BEFORE INTERFACE ${MKL_INCLUDE})
  list(APPEND MKL_IMPORTED_TARGETS MKL::MKL)
endif() # MKL_LIBRARIES
