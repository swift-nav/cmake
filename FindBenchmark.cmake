include("GenericFindDependency")
option(BENCHMARK_ENABLE_TESTING "" OFF)
option(BENCHMARK_ENABLE_INSTALL "" OFF)
option(BENCHMARK_ENABLE_GTEST_TESTS "" OFF)
option(BENCHMARK_ENABLE_EXCEPTIONS "" OFF)
GenericFindDependency(
    TARGET benchmark
    SYSTEM_INCLUDES
    )

# We've found that other packages expect to have the LIBRT variable
# not set, so having it cached can cause issues
unset(LIBRT)
unset(LIBRT CACHE)
