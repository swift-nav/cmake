include("GenericFindDependency")

option(starling_ENABLE_TESTS "" OFF)
option(starling_ENABLE_TEST_LIBS "" OFF)
option(starling_ENABLE_EXAMPLES "" OFF)

GenericFindDependency(
  TARGET pvt-runner-lib
  ADDITIONAL_TARGETS
    sensorfusion
    pvt_driver
    pvt-engine
    pvt-common
    starling-util
  SOURCE_DIR starling
  SYSTEM_HEADER_FILE "pvt_driver/runner/pvt_runner.h"
)
