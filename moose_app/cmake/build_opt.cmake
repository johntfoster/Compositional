# Build the application with the repository's configured MOOSE runtime.
#
# Invoke from the repository root with:
#   cmake -P moose_app/cmake/build_opt.cmake

set(REPOSITORY_ROOT "${CMAKE_CURRENT_LIST_DIR}/../..")
get_filename_component(REPOSITORY_ROOT "${REPOSITORY_ROOT}" REALPATH)

if(DEFINED ENV{MOOSE_FRAMEWORK_PATH})
  set(MOOSE_FRAMEWORK_PATH "$ENV{MOOSE_FRAMEWORK_PATH}")
else()
  set(MOOSE_FRAMEWORK_PATH ".agent-runtime/moose")
endif()
if(IS_ABSOLUTE "${MOOSE_FRAMEWORK_PATH}")
  message(FATAL_ERROR "MOOSE_FRAMEWORK_PATH must be repository-relative")
endif()

set(MOOSE_DIR "${REPOSITORY_ROOT}/${MOOSE_FRAMEWORK_PATH}")
set(RUNTIME_DIR "${REPOSITORY_ROOT}/.agent-runtime")
set(LOCK_DIR "${RUNTIME_DIR}/locks")
set(SPE_ACCEPTANCE_LOCK "${LOCK_DIR}/spe_acceptance.lock")
set(MOOSE_ENV_HELPER
    "${REPOSITORY_ROOT}/agent_environment/skills/setup-moose-conda/scripts/moose_conda_env.sh")

if(NOT EXISTS "${MOOSE_DIR}/framework/Makefile")
  message(FATAL_ERROR
    "Expected MOOSE checkout is unavailable at ${MOOSE_FRAMEWORK_PATH}; "
    "run tools/agentctl provision moose after authorization")
endif()
if(NOT EXISTS "${MOOSE_ENV_HELPER}")
  message(FATAL_ERROR "Expected repository MOOSE environment helper is unavailable")
endif()

file(MAKE_DIRECTORY "${LOCK_DIR}")
if(EXISTS "${SPE_ACCEPTANCE_LOCK}")
  file(READ "${SPE_ACCEPTANCE_LOCK}" spe_acceptance_owner)
  string(STRIP "${spe_acceptance_owner}" spe_acceptance_owner)
  message(FATAL_ERROR
    "A provenance-critical SPE run is active; defer this build until "
    ".agent-runtime/locks/spe_acceptance.lock clears:\n${spe_acceptance_owner}")
endif()
file(LOCK "${LOCK_DIR}/moose_build.lock"
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
    set(moose_status "<clean>")
  endif()
  message(STATUS "MOOSE ${label} HEAD: ${moose_head}")
  message(STATUS "MOOSE ${label} status:\n${moose_status}")
endfunction()

record_moose_state("pre-build")
execute_process(
  COMMAND "${MOOSE_ENV_HELPER}" verify
  WORKING_DIRECTORY "${REPOSITORY_ROOT}"
  COMMAND_ERROR_IS_FATAL ANY)

execute_process(
  COMMAND "${MOOSE_ENV_HELPER}" run -- make -j1 "MOOSE_DIR=${MOOSE_DIR}" METHOD=opt
  WORKING_DIRECTORY "${REPOSITORY_ROOT}/moose_app"
  RESULT_VARIABLE build_result)

record_moose_state("post-build")
execute_process(
  COMMAND "${MOOSE_ENV_HELPER}" verify
  WORKING_DIRECTORY "${REPOSITORY_ROOT}"
  COMMAND_ERROR_IS_FATAL ANY)

if(NOT build_result EQUAL 0)
  message(FATAL_ERROR "Optimized MOOSE application build failed with status ${build_result}")
endif()
