include("GenericFindDependency")
option(starling_ENABLE_TESTS "" OFF)
option(starling_ENABLE_EXAMPLES "" OFF)
GenericFindDependency(
    TARGET starling
    SYSTEM_HEADER_FILE "starling/starling.h"
    SYSTEM_INCLUDES
    )
