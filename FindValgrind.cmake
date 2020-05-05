include("GenericFindDependency")
option(VALGRIND_ENABLE "" OFF)
GenericFindDependency(
    TARGET valgrind
    SYSTEM_INCLUDES
    )
