#
# OVERVIEW
#
# This module is intended to be a generic module when calling a python script
# from another cmake module.
#
# USAGE
#
# The module can be used together with a custom_command or custom_target.
# See example below:
#
# COMMAND ${CMAKE_COMMAND} -DScript=${Script}
#                          -DInput_directory=${Input_directory}
#                          -DOutput_directory=${Output_directory}
#                          -DScript_options=${Script_options}
#                          -DLabel=${Label}
#                          -DWrapper_settings=${Wrapper_settings}
#                          -P <path_to_module>/PythonRunner.cmake
#
# GLOBAL VARIABLES
#  -DScript:           Set this variable to the name of the python file to be
#                      executed.
#  -DInput_directory:  This variable defines the input directory.
#  -DOutput_directory: This variable sets the output directory.
#  -DScript_options:   Use this variable to forward specific options to the
#                      python script.
#  -DLabel:            Use this variable to set a specific name or label.
#                      For example to apply specific messages after the
#                      executed process.
#  -Wrapper_settings:  Use this variable to customize the behavior after the
#                      executed process.
#
execute_process(
    COMMAND python ${Script} ${Input_directory} ${Output_directory} ${Script_options}
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/scripts
    OUTPUT_VARIABLE result
)
