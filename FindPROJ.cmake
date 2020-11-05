include("GenericFindDependency")
option(ENABLE_TIFF "" OFF)
option(ENABLE_CURL "" OFF)
option(BUILD_PROJSYNC "" OFF)
option(BUILD_TESTING "" OFF)
GenericFindDependency(
  TARGET proj
  SOURCE_DIR "PROJ"
  )
