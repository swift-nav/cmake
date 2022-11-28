include("GenericFindDependency")

option(ABSL_PROPAGATE_CXX_STD "Use CMake C++ standard meta features (e.g. cxx_std_11) that propagate to targets that link to Abseil" true)

GenericFindDependency(
  TARGET grpc++
  SOURCE_DIR grpc
  ADDITIONAL_TARGETS
    libprotobuf
  SYSTEM_INCLUDES
)
