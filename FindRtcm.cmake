include("GenericFindDependency")
option(librtcm_ENABLE_TESTS "" OFF)
GenericFindDependency(
    TARGET rtcm
    SOURCE_DIR "c"
    SYSTEM_HEADER_FILE "rtcm3/bits.h"
    )
