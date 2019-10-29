include("GenericFindDependency")
option(CHECK_ENABLE_TESTS "" OFF)
option(CHECK_INSTALL "" OFF)
GenericFindDependency(
  TARGET check
  SYSTEM_INCLUDES
  )
