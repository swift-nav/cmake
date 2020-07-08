include("GenericFindDependency")
option(libubx_ENABLE_TESTS "" OFF)
GenericFindDependency(
    TARGET ubx
    SOURCE_DIR "c"
    )
