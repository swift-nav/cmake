include("GenericFindDependency")
option(pal_ENABLE_TESTS "" OFF)
option(pal_ENABLE_EXAMPLES "" OFF)
option(pal_ENABLE_TEST_LIBS "" OFF)
GenericFindDependency(
  TARGET pal
  ADDITIONAL_TARGETS pal++
)
