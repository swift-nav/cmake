include("GenericFindDependency")
option(JsonBuildTests "" OFF)
GenericFindDependency(
    TARGET "nlohmann_json"
    SOURCE_DIR "json"
    SYSTEM_INCLUDES
    )

