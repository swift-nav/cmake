include("GenericFindDependency")
option(swiftlets_ENABLE_TESTS "" OFF)
option(pal_ENABLE_EXAMPLES "" OFF)
GenericFindDependency(
    TARGET swiftlets
    SOURCE_DIR swiftlets
    SYSTEM_INCLUDES
)
