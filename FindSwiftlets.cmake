include("GenericFindDependency")
option(swiftlets_ENABLE_TESTS "" OFF)
option(swiftlets_ENABLE_TEST_LIBS "" OFF)
GenericFindDependency(
    TARGET swiftlets
    SOURCE_DIR swiftlets
)
