include("GenericFindDependency")
option(GFLAGS_STRIP_INTERNAL_FLAG_HELP "Hide help from GFLAGS modules" true)
GenericFindDependency(
  TARGET gflags
  SOURCE_DIR "googleflags"
  SYSTEM_INCLUDES
)
