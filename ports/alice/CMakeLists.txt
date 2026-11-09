# alice - ReXGlue Recompiled Project
#
# SDK boilerplate lives in generated/rexglue.cmake.
# Started from the ReXGlue SDK `rexglue init` template (BSD-3-Clause, see THIRD_PARTY_NOTICES.md).
# Needs an SDK with tekken6-recomp's patch applied (GPU plugins): see sdk-patch/README.txt.

cmake_minimum_required(VERSION 3.25)
project(alice LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(REXSDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/rexglue-sdk"
    CACHE PATH "Path to rexglue-sdk source tree")
include(generated/rexglue.cmake)
# The SDK sets REXGLUE_ROOT only in its own directory scope, but its macOS
# Vulkan staging helper runs from this one and reads the MoltenVK ICD from it.
set(REXGLUE_ROOT "${REXSDK_DIR}")

# Sources
set(ALICE_SOURCES
    src/main.cpp
)

if(WIN32)
    add_executable(alice WIN32 ${ALICE_SOURCES})
else()
    add_executable(alice ${ALICE_SOURCES})
endif()

rexglue_setup_target(alice GPU_PLUGINS xenos)
# The GPU plugin is loaded at run time, so copy it beside the game binary on every build.
add_custom_target(alice_gpu_plugin_copy
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "$<TARGET_FILE:rexgpu-xenos>" "${CMAKE_CURRENT_BINARY_DIR}/"
    DEPENDS rexgpu-xenos
    VERBATIM
)
add_dependencies(alice alice_gpu_plugin_copy)
target_link_libraries(alice PRIVATE rex::ui)
# The function registration file is one huge function; optimizing it takes
# >10 minutes and many GB of RAM, and it only runs once at startup.
set_source_files_properties(generated/default/alice_register.cpp generated/default/alice_init.cpp
    TARGET_DIRECTORY alice_recomp PROPERTIES COMPILE_OPTIONS "-O0" SKIP_PRECOMPILE_HEADERS ON)
