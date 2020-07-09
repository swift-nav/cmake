include("GenericFindDependency")
option(nanopb_BUILD_GENERATOR "" OFF)
GenericFindDependency(
  TARGET protobuf-nanopb
  SOURCE_DIR "third_party/nanopb"
  SYSTEM_INCLUDES
  )

