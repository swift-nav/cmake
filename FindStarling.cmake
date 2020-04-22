include("GenericFindDependency")
option(starling_ENABLE_TESTS "" OFF)
option(starling_ENABLE_EXAMPLES "" OFF)
GenericFindDependency(
    TARGET pvt-runner-lib
    SOURCE_DIR starling
    SYSTEM_HEADER_FILE "pvt_driver/runner/pvt_runner.h"
    SYSTEM_INCLUDES
)
