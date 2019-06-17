include("GenericFindDependency")
GenericFindDependency(
    TARGET gnss_converters
    SOURCE_DIR "gnss-converters/c"
    SYSTEM_HEADER_FILE "gnss-converters/nmea.h"
    SYSTEM_INCLUDES
    )
