include("GenericFindDependency")

option(starling_ENABLE_TESTS "" OFF)
option(starling_ENABLE_TEST_LIBS "" OFF)
option(starling_ENABLE_EXAMPLES "" OFF)

GenericFindDependency(
  TARGET pvt-runner-lib
  ADDITIONAL_TARGETS
    math_routines
    sensorfusion
    pvt_driver
    pvt-common
    pvt-engine
    pvt-runner
    pvt-sbp-logging
    pvt-sizes
    pvt-version
    starling-build-config
    starling-util
  SYSTEM_HEADER_FILE "pvt_driver/runner/pvt_runner.h"
)
