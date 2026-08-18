# SPE2 axisymmetric production fields. Coordinate 0 is radial and coordinate 1
# is axial/depth, so ux and uy are the radial and axial solid displacements.
[Variables]
  [ux]
    family = LAGRANGE
    order = SECOND
    scaling = 1e-9
  []
  [uy]
    family = LAGRANGE
    order = SECOND
    scaling = 1e-9
  []
  [oil_pressure]
    family = LAGRANGE
    order = FIRST
    scaling = 1e-7
  []
  [oil_pressure_enrichment]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 0
    scaling = 1e-7
  []
  [solution_gas_oil_ratio]
    family = LAGRANGE
    order = FIRST
  []
  [water_saturation]
    # The quadratic Bernstein basis is the higher-order CG saturation basis.
    family = BERNSTEIN
    order = SECOND
  []
  [water_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_saturation]
    family = BERNSTEIN
    order = SECOND
  []
  [gas_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_oil_pressure_difference]
    # P2 CG closure field for gamma_w-gamma_o + omega_w^+-omega_o^+
    # plus the water saturation Onsager force relative to oil.
    family = LAGRANGE
    order = SECOND
    scaling = 1e-7
  []
  [gas_oil_pressure_difference]
    family = LAGRANGE
    order = SECOND
    scaling = 1e-7
  []
  [tau]
    family = LAGRANGE
    order = FIRST
  []
  [tau_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_phase_transformation_rate]
    # The mu/tau kinetic closure is local and has no rate-gradient term.
    # The closure residual is satisfied to O(1e-12) at the physical solution;
    # an O(1e8) row scaling inflates that satisfied residual above the
    # nl_abs_tol convergence gate and forces the Newton solve to grind to
    # max_its.  Keep the row unscaled so the closure residual is measured in
    # its physical units (same fix as spe1_case1_q2_eg_transient.i).
    family = MONOMIAL
    order = SECOND
    scaling = 1
  []
  [fluid_temperature]
    family = LAGRANGE
    order = FIRST
    scaling = 4e-7
  []
  [solid_temperature]
    family = LAGRANGE
    order = FIRST
    scaling = 4e-7
  []
  [matrix_reference_component_storage]
    # SPE2 porosity is discontinuous by layer. The conserved solid-reference
    # constituent therefore uses an element-local FE field; this is a DG/P0
    # Galerkin primary, not a finite-volume discretization.
    family = MONOMIAL
    order = CONSTANT
  []
  [producer_bhp_scalar]
    family = SCALAR
    order = FIRST
    initial_condition = 20684271.879504
    scaling = 1e-7
  []
[]

[AuxVariables]
  [water_saturation_bound]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_saturation_enrichment_bound]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_saturation_bound]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_saturation_enrichment_bound]
    family = MONOMIAL
    order = CONSTANT
  []
  [phase_transform_dissipation]
    family = MONOMIAL
    order = CONSTANT
  []
[]
