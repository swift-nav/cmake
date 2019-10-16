include("GenericFindDependency")
option(pal++_ENABLE_TESTS "" OFF)
GenericFindDependency(
    TARGET pal++
    SYSTEM_INCLUDES
)