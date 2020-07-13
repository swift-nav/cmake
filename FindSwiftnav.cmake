include("GenericFindDependency")
option(libswiftnav_ENABLE_TESTS "" OFF)
GenericFindDependency(
    TARGET swiftnav
    SYSTEM_HEADER_FILE "swiftnav/bits.h"
    )
