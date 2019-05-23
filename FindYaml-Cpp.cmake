include("GenericFindDependency")
option(YAML_CPP_BUILD_TOOLS "Enable testing and parse tools" OFF)
option(YAML_CPP_BUILD_CONTRIB "Enable contrib stuff in library" OFF)
GenericFindDependency(
    TARGET "yaml-cpp"
    SYSTEM_INCLUDES
    )
