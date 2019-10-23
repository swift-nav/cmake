include("GenericFindDependency")
option(pal++_ENABLE_TESTS "" OFF)
GenericFindDependency(
    TARGET pal++
    SOURCE_DIR libpal_cpp
    SYSTEM_INCLUDES
)