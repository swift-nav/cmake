include("GenericFindDependency")
option (NLOPT_PYTHON "build python bindings" OFF)
option (NLOPT_OCTAVE "build octave bindings" OFF)
option (NLOPT_MATLAB "build matlab bindings" OFF)
option (NLOPT_GUILE "build guile bindings" OFF)
option (NLOPT_SWIG "use SWIG to build bindings" OFF)
GenericFindDependency(
    TARGET "nlopt"
    SYSTEM_INCLUDES
    )
