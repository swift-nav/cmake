include("GenericFindDependency")
option(protocol_BUILD_TESTS "" OFF)
GenericFindDependency(
    TARGET "libprotobuf"
    SOURCE_DIR "protobuf/cmake"
    SYSTEM_INCLUDES
    )
