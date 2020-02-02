include("GenericFindDependency")
GenericFindDependency(
    TARGET gtest
    SOURCE_DIR "googletest"
    SYSTEM_INCLUDES
    )
mark_target_as_system_includes(gmock)
