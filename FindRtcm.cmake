include("GenericFindDependency")
GenericFindDependency(
    TARGET rtcm
    SOURCE_DIR "c"
    SYSTEM_HEADER_FILE "rtcm3/bits.h"
    SYSTEM_INCLUDES
    )
