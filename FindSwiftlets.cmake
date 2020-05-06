include("GenericFindDependency")
option(swiftlets_ENABLE_TESTS "" OFF)
GenericFindDependency(
    TARGET swiftlets
    SOURCE_DIR swiftlets
    SYSTEM_INCLUDES
)
