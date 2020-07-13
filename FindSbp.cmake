include("GenericFindDependency")
option(libsbp_ENABLE_TESTS "" OFF)
option(libsbp_ENABLE_DOCS "" OFF)
GenericFindDependency(
    TARGET sbp
    SOURCE_DIR "c"
    )
