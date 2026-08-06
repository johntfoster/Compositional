!include ../../../examples/spe1_case1_q2_eg_transient.i

# One cell in each official vertical layer gives an 18-element TET10 problem.
# It retains the production residuals and constitutive objects while providing
# a practical regression gate for the fully coupled nonequilibrium system. The
# harness supplies the reduced mesh, completion boxes, short time interval,
# focused outputs, and file base as command-line overrides so they take
# precedence over the included production values.
