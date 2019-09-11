include("GenericFindDependency")
option(BENCHMARK_ENABLE_TESTING "" OFF)
option(BENCHMARK_ENABLE_INSTALL "" OFF)
option(BENCHMARK_ENABLE_GTEST_TESTS "" OFF)
option(BENCHMARK_ENABLE_EXCEPTIONS "" OFF)
GenericFindDependency(
    TARGET benchmark
    SYSTEM_INCLUDES
    )
