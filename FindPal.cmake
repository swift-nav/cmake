include("GenericFindDependency")
option(pal_ENABLE_TESTS "" OFF)
option(pal_ENABLE_EXAMPLES "" OFF)
GenericFindDependency(
  TARGET pal
  SYSTEM_INCLUDES
  )
