include("GenericFindDependency")
GenericFindDependency(
    TARGET gtest
    ADDITIONAL_TARGETS gmock
    SOURCE_DIR "googletest"
    SYSTEM_INCLUDES
)