include("GenericFindDependency")
option(libixcom_ENABLE_TESTS "" OFF)
GenericFindDependency(
    TARGET ixcom
    SOURCE_DIR "c"
    SYSTEM_INCLUDES
    )
