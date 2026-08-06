# Build the application with the repository's fixed MOOSE module profile.
#
# Invoke from the repository root with:
#   cmake -P moose_app/cmake/build_opt.cmake
#
# The application uses MOOSE's Makefile build interface.  This CMake script is
# a reproducible command wrapper; module selection remains in moose_app/Makefile.

set(REPOSITORY_ROOT "${CMAKE_CURRENT_LIST_DIR}/../..")
get_filename_component(REPOSITORY_ROOT "${REPOSITORY_ROOT}" REALPATH)
set(MOOSE_DIR "/home/jfoster/.local/moose")
set(CONDA "/home/jfoster/miniconda3/bin/conda")
set(SPE_ACCEPTANCE_LOCK "/tmp/multicomponent_reactive_flow_spe_acceptance.lock")
set(VERIFY_MOOSE_ENV
    "${REPOSITORY_ROOT}/.codex/skills/setup-moose-conda/scripts/verify_moose_env.sh")

if(NOT EXISTS "${CONDA}")
  message(FATAL_ERROR "Expected Conda executable is unavailable: ${CONDA}")
endif()
if(NOT EXISTS "${MOOSE_DIR}/framework/Makefile")
  message(FATAL_ERROR "Expected MOOSE checkout is unavailable: ${MOOSE_DIR}")
endif()
if(NOT EXISTS "${VERIFY_MOOSE_ENV}")
  message(FATAL_ERROR "Expected MOOSE environment audit is unavailable: ${VERIFY_MOOSE_ENV}")
endif()
if(EXISTS "${SPE_ACCEPTANCE_LOCK}")
  file(READ "${SPE_ACCEPTANCE_LOCK}" spe_acceptance_owner)
  string(STRIP "${spe_acceptance_owner}" spe_acceptance_owner)
  message(FATAL_ERROR
    "A provenance-critical SPE run is active; defer this build until the lock clears: "
    "${SPE_ACCEPTANCE_LOCK}\n${spe_acceptance_owner}")
endif()
file(LOCK "/tmp/multicomponent_reactive_flow_moose_build.lock"
     GUARD PROCESS TIMEOUT 0 RESULT_VARIABLE build_lock_result)
if(NOT build_lock_result STREQUAL "0")
  message(FATAL_ERROR
    "Another guarded MOOSE application build is active; retry after it completes: "
    "${build_lock_result}")
endif()

function(record_moose_state label)
  execute_process(
    COMMAND git -C "${MOOSE_DIR}" rev-parse HEAD
    OUTPUT_VARIABLE moose_head
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
  execute_process(
    COMMAND git -C "${MOOSE_DIR}" status --short --untracked-files=all
    OUTPUT_VARIABLE moose_status
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
  if(moose_status STREQUAL "")
    set(moose_status "<clean>" )
  endif()
  message(STATUS "MOOSE ${label} HEAD: ${moose_head}")
  message(STATUS "MOOSE ${label} status:\n${moose_status}")
endfunction()

record_moose_state("pre-build")
execute_process(COMMAND "${VERIFY_MOOSE_ENV}" COMMAND_ERROR_IS_FATAL ANY)

execute_process(
  COMMAND "${CONDA}" run --no-capture-output -n moose
          make -j1 "MOOSE_DIR=${MOOSE_DIR}" METHOD=opt
  WORKING_DIRECTORY "${REPOSITORY_ROOT}/moose_app"
  RESULT_VARIABLE build_result)

record_moose_state("post-build")
execute_process(COMMAND "${VERIFY_MOOSE_ENV}" COMMAND_ERROR_IS_FATAL ANY)

if(NOT build_result EQUAL 0)
  message(FATAL_ERROR "Optimized MOOSE application build failed with status ${build_result}")
endif()
