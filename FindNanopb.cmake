include("GenericFindDependency")
option(nanopb_BUILD_GENERATOR "" ON)

GenericFindDependency(
  TARGET protobuf-nanopb
  SOURCE_DIR "nanopb"
  SYSTEM_INCLUDES
)
