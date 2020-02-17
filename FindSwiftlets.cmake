include("GenericFindDependency")
option(swiftlets_ENABLE_DOCS "" OFF)
option(swiftlets_ENABLE_TESTS "" OFF)
GenericFindDependency(
  TARGET swiftlets
  SYSTEM_INCLUDES
  )
