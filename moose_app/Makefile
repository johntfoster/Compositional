###############################################################################
################### MOOSE Application Standard Makefile #######################
###############################################################################

MOOSE_SUBMODULE    := $(CURDIR)/moose
ifneq ($(wildcard $(MOOSE_SUBMODULE)/framework/Makefile),)
  MOOSE_DIR        ?= $(MOOSE_SUBMODULE)
else
  MOOSE_DIR        ?= $(HOME)/.local/moose
endif

FRAMEWORK_DIR      := $(MOOSE_DIR)/framework
include $(FRAMEWORK_DIR)/build.mk
include $(FRAMEWORK_DIR)/moose.mk

################################## MODULES ####################################

ALL_MODULES                 := no

CHEMICAL_REACTIONS          := no
CONTACT                     := no
ELECTROMAGNETICS            := no
EXTERNAL_PETSC_SOLVER       := no
FLUID_PROPERTIES            := no
FSI                         := no
FUNCTIONAL_EXPANSION_TOOLS  := no
GEOCHEMISTRY                := no
HEAT_TRANSFER               := no
LEVEL_SET                   := no
MISC                        := no
NAVIER_STOKES               := no
OPTIMIZATION                := no
PERIDYNAMICS                := no
PHASE_FIELD                 := no
POROUS_FLOW                 := no
RAY_TRACING                 := no
RDG                         := no
REACTOR                     := no
RICHARDS                    := no
SCALAR_TRANSPORT            := no
SOLID_MECHANICS             := yes
SOLID_PROPERTIES            := no
STOCHASTIC_TOOLS            := no
SUBCHANNEL                  := no
THERMAL_HYDRAULICS          := no
XFEM                        := no

include $(MOOSE_DIR)/modules/modules.mk

APPLICATION_DIR    := $(CURDIR)
APPLICATION_NAME   := multicomponent_reactive_flow
BUILD_EXEC         := yes
GEN_REVISION       := no

include            $(FRAMEWORK_DIR)/app.mk
