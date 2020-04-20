include("GenericFindDependency")
option(starling_ENABLE_TESTS "" OFF)
option(starling_ENABLE_EXAMPLES "" OFF)
GenericFindDependency(
    TARGET pvt_driver
    SYSTEM_HEADER_FILE "pvt_driver/pvt_driver.h"
    SYSTEM_INCLUDES
    )
