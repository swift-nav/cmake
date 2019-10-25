include("GenericFindDependency")
option(CHECK_ENABLE_TESTS "" OFF)
GenericFindDependency(
  TARGET check
  SYSTEM_INCLUDES
  )
