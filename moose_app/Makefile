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

CHEMICAL_REACTIONS          := yes
CONTACT                     := no
EXTERNAL_PETSC_SOLVER       := no
FLUID_PROPERTIES            := yes
FSI                         := no
FUNCTIONAL_EXPANSION_TOOLS  := no
GEOCHEMISTRY                := no
HEAT_TRANSFER               := no
LEVEL_SET                   := no
MISC                        := no
NAVIER_STOKES               := no
PHASE_FIELD                 := no
POROUS_FLOW                 := yes
RAY_TRACING                 := no
RDG                         := no
RICHARDS                    := no
SOLID_MECHANICS             := yes
STOCHASTIC_TOOLS            := no
XFEM                        := no

include $(MOOSE_DIR)/modules/modules.mk

APPLICATION_DIR    := $(CURDIR)
APPLICATION_NAME   := multicomponent_reactive_flow
BUILD_EXEC         := yes
GEN_REVISION       := no

include            $(FRAMEWORK_DIR)/app.mk
