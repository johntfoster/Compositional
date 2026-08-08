# First coupled finite-deformation SPE1 Case 1 Q2/EG initialization slice in SI units.
# The 300 physical cells are mapped to 1800 TET10 elements. The official ROCK
# compressibility supplies the drained skeleton bulk modulus. Because SPE1
# does not specify shear response, nu=0.25 is an explicit untuned constitutive
# specialization; B=1 is the incompressible-grain limit. External total
# traction is zero except for the bottom normal support that carries mixture
# weight; three in-plane nodal constraints remove the remaining rigid motion. Wells
# are inactive in this first slice so the initial coupled matrix/fluid state is
# established before completion controls and the official schedule are added.
spe1_use_pressure_dependent_rock_porosity = false
!include ../input/includes/mesh/spe1_case1_3d_q2_tet10.i

[Variables]
  inactive = 'injector_bhp_scalar producer_bhp_scalar'
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
  [uz]
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
    scaling = 1e-7
  []
  [solution_gas_oil_ratio]
    family = LAGRANGE
    order = FIRST
  []
  [water_saturation]
    # The continuous quadratic backbone and element-constant enrichment form
    # the requested higher-order EG saturation field.
    family = BERNSTEIN
    order = SECOND
  []
  [water_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_saturation]
    # A quadratic Bernstein basis spans the requested continuous P2 space.
    family = BERNSTEIN
    order = SECOND
  []
  [gas_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
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
    # The manuscript kinetic closure is local and contains no rate gradient.
    # An element-local quadratic field resolves mu/tau without imposing an
    # artificial interelement continuity constraint on the conversion rate.
    # The closure residual is satisfied to O(1e-12) at the physical solution;
    # an O(1e8) row scaling inflates that satisfied residual above the
    # nl_abs_tol = 1e-8 convergence gate and forces the Newton solve to grind
    # to max_its.  Keep the row unscaled (identity) so the closure residual is
    # measured in its physical units.
    family = MONOMIAL
    order = SECOND
    scaling = 1
  []
  [fluid_temperature]
    family = LAGRANGE
    order = FIRST
    # Normalize the J*C*dot(theta) row by the declared 2.5e6 J/(m^3 K)
    # storage scale; this changes solver conditioning, not the energy equation.
    scaling = 4e-7
  []
  [solid_temperature]
    family = LAGRANGE
    order = FIRST
    scaling = 4e-7
  []
  [matrix_reference_component_storage]
    family = LAGRANGE
    order = FIRST
  []
  [injector_bhp_scalar]
    family = SCALAR
    order = FIRST
    initial_condition = 36700000
    scaling = 1e-7
  []
  [producer_bhp_scalar]
    family = SCALAR
    order = FIRST
    initial_condition = 20000000
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

[Functions]
  [initial_oil_pressure]
    type = PiecewiseLinear
    axis = z
    x = '2540.508 2548.128 2560.32'
    y = '32972876.15288512 33019779.87273818 33094835.007206395'
  []
  [initial_pressure_vertex]
    type = PiecewiseLinear
    axis = z
    # P1 vertex-layer version of initial_oil_pressure for the diagonal
    # reference prestress.  The initial_oil_pressure breakpoints sit at the
    # P2 mid-edge levels, so that clamped piecewise-linear function does not
    # cancel the P1 vertex-interpolated reconstructed pressure inside the top
    # and bottom layers (leaving an O(10 kPa) residual horizontal stress).
    # Breakpoints here coincide with the P1 vertex layers, so the diagonal
    # prestress equals the P1 pressure field pointwise at F=I and total
    # P_xx = P_yy = 0 at the IC, consistent with the zz comment below.
    x = '2537.46 2543.556 2552.7 2567.94'
    y = '32972876.15288512 32991637.64082712 33047925.54816376 33094835.007206395'
  []
  [geostatic_prestress_zz]
    type = PiecewiseLinear
    axis = z
    # In-situ stress initialization.  The SPE1 pore-pressure profile alone
    # balances only the fluid-weight share of the mixture body force; the
    # conserved solid overburden (rho_mix*g ~ 20168.7 Pa/m at the IC, with
    # rho_mix = phi_s*rho_s + phi*(S_w*rho_w + S_o*rho_o + S_g*rho_g)) must be
    # carried by the skeleton reference stress so that total P_zz at F=I is
    # -rho_mix*g*(z - z_top) with a traction-free top at z = 2537.46.  This
    # equals initial_oil_pressure - 20168.7*(z - 2537.46) at every depth.
    # NOTE: breakpoints must coincide with the P1 vertex layers (the layer
    # boundaries) so that the piecewise-linear prestress cancels the P1
    # vertex-interpolated reconstructed pressure exactly.  Breakpoints at the
    # P2 mid-edge levels made the clamped end segments inconsistent with the
    # P1 pressure interpolation near the top and bottom layers.
    x = '2537.46 2543.556 2552.7 2567.94'
    y = '32972876.15288512 32868689.245626 32740554.560164 32480093.031206'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [initial_solution_gas_oil_ratio]
    type = ParsedFunction
    expression = '226.19666048237477'
  []
  [initial_water_saturation]
    type = ParsedFunction
    expression = '0.12'
  []
  [initial_gas_saturation]
    type = ParsedFunction
    expression = '0'
  []
[]

[Problem]
[]

[ICs]
  [oil_pressure]
    type = FunctionIC
    variable = oil_pressure
    # Vertex-layer profile: the reconstructed pressure must equal the P1
    # vertex-interpolated diagonal prestress reference pointwise so that the
    # total stress is exactly the geostatic profile -rho_mix*g*(z - z_top) at
    # F=I.  The mid-edge-clamped initial_oil_pressure leaves an O(10 kPa)
    # in-layer stress imbalance that drives a spurious O(100 m) initial
    # momentum residual.
    function = initial_pressure_vertex
  []
  [oil_pressure_enrichment]
    type = ConstantIC
    variable = oil_pressure_enrichment
    value = 0
  []
  [solution_gas_oil_ratio]
    type = ConstantIC
    variable = solution_gas_oil_ratio
    value = 226.19666048237477
  []
  [water_saturation]
    type = ConstantIC
    variable = water_saturation
    value = 0.12
  []
  [gas_saturation]
    type = ConstantIC
    variable = gas_saturation
    value = 0
  []
  [tau]
    type = ConstantIC
    variable = tau
    value = 0
  []
  [gas_phase_transformation_rate]
    type = ConstantIC
    variable = gas_phase_transformation_rate
    value = 0
  []
  [fluid_temperature]
    type = ConstantIC
    variable = fluid_temperature
    value = 333.15
  []
  [solid_temperature]
    type = ConstantIC
    variable = solid_temperature
    value = 333.15
  []
  [matrix_reference_component_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    value = 1855
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix oil gas water'
    reference_phase = matrix
    momentum_models = 'reference relative_flux relative_flux relative_flux'
  []
[]

[Materials]
  inactive = 'injector_relative_permeability injector producer'
  [solid_kinematics]
    type = ADSolidReferenceKinematics
    displacements = 'ux uy uz'
  []
  [matrix_effective_stress]
    type = ADCompressibleNeoHookeanReferenceStressMaterial
    # K=1/c_r=2.298252386e9 Pa and nu=0.25 give lambda=mu=1.378951432e9 Pa.
    shear_modulus = 1.3789514317427287e9
    lame_lambda = 1.3789514317427287e9
  []
  [matrix_reference_prestress]
    type = ADGenericFunctionRankTwoTensor
    # The SPE1 pressure profile defines a loaded reference state.  At F=I,
    # the diagonal cancels the initial Biot pressure contribution exactly,
    # and the zz component adds the geostatic skeleton overburden
    # -rho_mix*g*(z - z_top) so the reference configuration is a true in-situ
    # equilibrium (total P_zz = -rho_mix*g*(z - z_top), traction-free top);
    # subsequent pressure/deformation increments remain fully coupled.
    tensor_functions = 'initial_pressure_vertex zero zero zero initial_pressure_vertex zero zero zero geostatic_prestress_zz'
    tensor_name = matrix_reference_prestress
  []
  [oil_pressure_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe1_oil_pressure
    backbone = oil_pressure
    enrichment = oil_pressure_enrichment
  []
  [water_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe1_water_saturation
    backbone = water_saturation
    enrichment = water_saturation_enrichment
  []
  [gas_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe1_gas_saturation
    backbone = gas_saturation
    enrichment = gas_saturation_enrichment
    # Both quadratic Bernstein coefficients and the P0 enrichment are
    # independently lower-bounded. Their nonnegative bases form partitions
    # of unity, so identity reconstruction is pointwise nonnegative and
    # permits exact phase disappearance.
    value_transform = identity
  []
  [tau_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe1_tau
    backbone = tau
    enrichment = tau_enrichment
  []
  [matrix_total_stress]
    type = ADReferenceSolidStressMaterial
    equivalent_pressure_total_name = spe1_oil_pressure_total
    biot_coefficient = 1
    reference_prestress_name = matrix_reference_prestress
  []
[]

!include ../input/includes/materials/solid_phase_mass_volume.i
!include ../input/includes/materials/spe1_case1_black_oil_pvt.i

[Materials]
  [layer_1_water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '1 11'
    phase = water
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_water_intrinsic_density
    permeability = 4.9346165e-13
    viscosity_name = benchmark_black_oil_water_viscosity
    relative_permeability_name = black_oil_water_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = water_darcy_mobility
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
  []
  [layer_2_water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = 2
    phase = water
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_water_intrinsic_density
    permeability = 4.9346165e-14
    viscosity_name = benchmark_black_oil_water_viscosity
    relative_permeability_name = black_oil_water_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = water_darcy_mobility
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
  []
  [layer_3_water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '3 13'
    phase = water
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_water_intrinsic_density
    permeability = 1.9738466e-13
    viscosity_name = benchmark_black_oil_water_viscosity
    relative_permeability_name = black_oil_water_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = water_darcy_mobility
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
  []
  [layer_1_oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '1 11'
    phase = oil
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    permeability = 4.9346165e-13
    viscosity_name = benchmark_black_oil_oil_viscosity
    relative_permeability_name = black_oil_oil_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = oil_darcy_mobility
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [layer_2_oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = 2
    phase = oil
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    permeability = 4.9346165e-14
    viscosity_name = benchmark_black_oil_oil_viscosity
    relative_permeability_name = black_oil_oil_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = oil_darcy_mobility
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [layer_3_oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '3 13'
    phase = oil
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    permeability = 1.9738466e-13
    viscosity_name = benchmark_black_oil_oil_viscosity
    relative_permeability_name = black_oil_oil_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = oil_darcy_mobility
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [layer_1_gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '1 11'
    phase = gas
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    permeability = 4.9346165e-13
    viscosity_name = benchmark_black_oil_gas_viscosity
    relative_permeability_name = black_oil_gas_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = gas_darcy_mobility
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
  []
  [layer_2_gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = 2
    phase = gas
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    permeability = 4.9346165e-14
    viscosity_name = benchmark_black_oil_gas_viscosity
    relative_permeability_name = black_oil_gas_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = gas_darcy_mobility
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
  []
  [layer_3_gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '3 13'
    phase = gas
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    permeability = 1.9738466e-13
    viscosity_name = benchmark_black_oil_gas_viscosity
    relative_permeability_name = black_oil_gas_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = gas_darcy_mobility
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
  []

  [zero_component_fraction]
    type = ADGenericConstantMaterial
    prop_names = zero_component_fraction
    prop_values = '0'
  []
  [water_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'zero_component_fraction zero_component_fraction benchmark_black_oil_water_component_mass_fraction_in_water'
    reference_component_flux_name = water_reference_component_flux
    reference_component_source_name = unused_water_source
  []
  [oil_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 1
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'benchmark_black_oil_oil_component_mass_fraction_in_oil zero_component_fraction zero_component_fraction'
    reference_component_flux_name = oil_reference_component_flux
    reference_component_source_name = unused_oil_source
  []
  [gas_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 2
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'benchmark_black_oil_gas_component_mass_fraction_in_oil benchmark_black_oil_gas_component_mass_fraction_in_gas zero_component_fraction'
    reference_component_flux_name = gas_reference_component_flux
    reference_component_source_name = unused_gas_source
  []

  # Nonequilibrium dissolved-gas/free-gas phase transformation.  These
  # objects expose the manuscript's mu, tau offsets, affinity, finite-rate
  # closure, stoichiometric sources, and nonnegative reaction power as
  # independently selectable input-deck properties/operators.
  [phase_transform_reference_thermodynamics]
    type = ADGenericConstantMaterial
    # SPE1 supplies no caloric equation of state. The matrix datum remains
    # zero, while the phase-transform material supplies the oil penalty and
    # free-gas reference datum used by the complete transfer-work algebra.
    prop_names = 'matrix_reference_neutral_mu matrix_reference_specific_helmholtz matrix_reference_pressure_work fluid_energy_storage solid_energy_storage fluid_external_energy_work solid_external_energy_work'
    prop_values = '0 0 0 2.5e6 2.5e6 0 0'
  []
  [water_reference_relative_velocity]
    type = ADReferenceRelativeVelocityMaterial
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
    bulk_density_name = benchmark_black_oil_water_bulk_phase_density
    deactivate_on_nonpositive_mass = true
    reference_relative_velocity_name = water_reference_relative_velocity
  []
  [oil_reference_relative_velocity]
    type = ADReferenceRelativeVelocityMaterial
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
    bulk_density_name = benchmark_black_oil_oil_bulk_phase_density
    phase_active_name = benchmark_black_oil_oil_active
    deactivate_on_nonpositive_mass = true
    reference_relative_velocity_name = oil_reference_relative_velocity
  []
  [gas_reference_relative_velocity]
    type = ADReferenceRelativeVelocityMaterial
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
    bulk_density_name = benchmark_black_oil_gas_bulk_phase_density
    phase_active_name = benchmark_black_oil_gas_active
    deactivate_on_nonpositive_mass = true
    reference_relative_velocity_name = gas_reference_relative_velocity
  []
  [water_saturation_entropy_viscosity]
    type = ADEntropyViscosityReferenceFluxMaterial
    scalar_name = spe1_water_saturation_total
    scalar_gradient_name = spe1_water_saturation_total_gradient
    scalar_dot_name = spe1_water_saturation_total_dot
    transport_velocity_name = water_reference_relative_velocity
    mass_coefficient_name = benchmark_black_oil_water_intrinsic_density
    entropy_storage_coefficient_name = benchmark_black_oil_water_reference_phase_mass_coefficient
    entropy_storage_coefficient_rate_name = benchmark_black_oil_water_reference_phase_mass_coefficient_rate
    source_names = 'spe1_well_water_reference_component_source'
    entropy = log_barrier
    lambda_linear = 1e-2
    lambda_entropy = 1e-2
    entropy_deviation_norm = 10
    differentiate_viscosity = false
    property_prefix = water_saturation_ev
  []
  [gas_saturation_entropy_viscosity]
    type = ADEntropyViscosityReferenceFluxMaterial
    scalar_name = spe1_gas_saturation_total
    scalar_gradient_name = spe1_gas_saturation_total_gradient
    scalar_dot_name = spe1_gas_saturation_total_dot
    transport_velocity_name = gas_reference_relative_velocity
    mass_coefficient_name = benchmark_black_oil_gas_intrinsic_density
    entropy_storage_coefficient_name = benchmark_black_oil_free_gas_reference_phase_mass_coefficient
    entropy_storage_coefficient_rate_name = benchmark_black_oil_free_gas_reference_phase_mass_coefficient_rate
    source_names = 'spe1_well_free_gas_reference_component_source spe1_phase_transfer_gas_reference_component_source_0'
    entropy = log_barrier
    lambda_linear = 1e-2
    lambda_entropy = 1e-2
    entropy_deviation_norm = 10
    differentiate_viscosity = false
    property_prefix = gas_saturation_ev
  []
  [spe1_phase_transform_mu]
    type = ADBlackOilPhaseTransformationThermodynamicsMaterial
    undersaturation_gap_name = benchmark_black_oil_undersaturation_gap
    oil_component_mass_fraction_name = benchmark_black_oil_oil_component_mass_fraction_in_oil
    dissolved_gas_mass_fraction_name = benchmark_black_oil_gas_component_mass_fraction_in_oil
    oil_intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    gas_intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    oil_bulk_density_name = benchmark_black_oil_oil_bulk_phase_density
    gas_bulk_density_name = benchmark_black_oil_gas_bulk_phase_density
    oil_pressure_name = spe1_oil_pressure_total
    gas_pressure_name = spe1_oil_pressure_total
    solution_gas_oil_ratio_scale = 226.19666048237477
    chemical_stiffness = 1
    oil_surface_density = 859.5507446467011
    gas_surface_density = 0.8537840978320755
    property_prefix = spe1_phase_transform
  []
  [tau_evolution]
    type = ADTauEvolutionMaterial
    tau = tau
    tau_enrichment = tau_enrichment
    reference_phase_displacements = 'ux uy uz'
    reference_neutral_potential_name = matrix_reference_neutral_mu
    reference_specific_helmholtz_name = matrix_reference_specific_helmholtz
    reference_pressure_work_name = matrix_reference_pressure_work
  []
  [oil_tau_derivative]
    type = ADPhaseTauMaterialDerivative
    phase = oil
    phase_registry = phases
    phase_kind = mobile
    tau = tau
    tau_enrichment = tau_enrichment
    bulk_density_name = benchmark_black_oil_oil_bulk_phase_density
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
    solid_displacements = 'ux uy uz'
    phase_active_name = benchmark_black_oil_oil_active
    deactivate_on_nonpositive_mass = true
  []
  [gas_tau_derivative]
    type = ADPhaseTauMaterialDerivative
    phase = gas
    phase_registry = phases
    phase_kind = mobile
    tau = tau
    tau_enrichment = tau_enrichment
    bulk_density_name = benchmark_black_oil_gas_bulk_phase_density
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
    solid_displacements = 'ux uy uz'
    phase_active_name = benchmark_black_oil_gas_active
    deactivate_on_nonpositive_mass = true
  []
  [spe1_phase_transfer]
    type = ADReactionNetworkMaterial
    phase_registry = phases
    phases = 'oil gas'
    components = gas
    reaction_rates = gas_phase_transformation_rate
    stoichiometric_coefficients = '-1 1'
    chemical_potential_names = 'spe1_phase_transform_dissolved_gas_electrochemical_mu spe1_phase_transform_free_gas_electrochemical_mu'
    phase_tau_offset_names = 'oil_tau_transfer_offset gas_tau_transfer_offset'
    kinetic_mobilities = '1e-8'
    forward_phase_active_names = benchmark_black_oil_oil_phase_availability
    reverse_phase_active_names = benchmark_black_oil_gas_phase_availability
    property_prefix = spe1_phase_transfer
  []
  [oil_gas_component_transfer_work]
    type = ADGeneralizedTransferWorkMaterial
    chemical_potential_name = spe1_phase_transform_dissolved_gas_electrochemical_mu
    specific_helmholtz_name = spe1_phase_transform_oil_phase_specific_helmholtz
    tau_transfer_offset_name = oil_tau_transfer_offset
    generalized_transfer_work_name = oil_gas_component_generalized_transfer_work
  []
  [free_gas_component_transfer_work]
    type = ADGeneralizedTransferWorkMaterial
    chemical_potential_name = spe1_phase_transform_free_gas_electrochemical_mu
    specific_helmholtz_name = spe1_phase_transform_gas_phase_specific_helmholtz
    tau_transfer_offset_name = gas_tau_transfer_offset
    generalized_transfer_work_name = free_gas_component_generalized_transfer_work
  []
  [phase_transform_affinity_identity]
    type = ADParsedMaterial
    material_property_names = 'spe1_phase_transfer_affinity_0 spe1_phase_transform_dissolved_to_free_affinity'
    property_name = spe1_phase_transform_affinity_identity_residual
    expression = 'spe1_phase_transfer_affinity_0-spe1_phase_transform_dissolved_to_free_affinity'
  []
  [phase_transform_generalized_force_identity]
    type = ADParsedMaterial
    material_property_names = 'spe1_phase_transfer_generalized_conversion_coefficient_0 spe1_phase_transfer_affinity_0 spe1_phase_transfer_transfer_work_correction_0'
    property_name = spe1_phase_transform_generalized_force_identity_residual
    expression = 'spe1_phase_transfer_generalized_conversion_coefficient_0-spe1_phase_transfer_affinity_0+spe1_phase_transfer_transfer_work_correction_0'
  []
  [phase_transform_power_identity]
    type = ADParsedMaterial
    coupled_variables = gas_phase_transformation_rate
    material_property_names = 'spe1_phase_transfer_reaction_power_0 spe1_phase_transfer_generalized_conversion_coefficient_0'
    property_name = spe1_phase_transform_power_identity_residual
    expression = 'spe1_phase_transfer_reaction_power_0-spe1_phase_transfer_generalized_conversion_coefficient_0*gas_phase_transformation_rate'
  []

  # Two-temperature specialization of the manuscript energy balances.
  # Equal initial temperatures make the SPE1 initialization adiabatic, while
  # both storage/transport equations remain live for later thermal schedules.
  [fluid_heat_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = fluid_temperature
    diffusivity = 1
    mobility_name = fluid_heat_mobility
    reference_flux_name = fluid_nonadvective_heat_flux
    reference_flux_divergence_name = fluid_nonadvective_heat_flux_divergence
  []
  [solid_heat_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = solid_temperature
    diffusivity = 2
    mobility_name = solid_heat_mobility
    reference_flux_name = solid_nonadvective_heat_flux
    reference_flux_divergence_name = solid_nonadvective_heat_flux_divergence
  []
  [mixture_gravity]
    type = ADMixtureGravityMaterial
    bulk_density_names = 'solid_current_bulk_density benchmark_black_oil_water_bulk_phase_density benchmark_black_oil_oil_bulk_phase_density benchmark_black_oil_gas_bulk_phase_density'
    gravity = '0 0 9.80665'
  []
  [fluid_energy_diagnostic]
    type = ADReferenceSubsystemEnergyDiagnosticMaterial
    temperature = fluid_temperature
    storage_coefficient_name = fluid_energy_storage
    reference_flux_divergence_name = fluid_nonadvective_heat_flux_divergence
    current_source_names = fluid_solid_energy_exchange
    current_external_work_names = fluid_external_energy_work
    generalized_transfer_work_names = 'oil_gas_component_generalized_transfer_work free_gas_component_generalized_transfer_work'
    current_component_source_names = 'spe1_phase_transfer_oil_current_component_source_0 spe1_phase_transfer_gas_current_component_source_0'
    property_prefix = fluid_energy
  []
  [solid_energy_diagnostic]
    type = ADReferenceSubsystemEnergyDiagnosticMaterial
    temperature = solid_temperature
    storage_coefficient_name = solid_energy_storage
    reference_flux_divergence_name = solid_nonadvective_heat_flux_divergence
    current_source_names = fluid_solid_energy_exchange
    source_scales = -1
    current_external_work_names = solid_external_energy_work
    property_prefix = solid_energy
  []
  [fluid_solid_energy_exchange]
    type = ADParsedMaterial
    coupled_variables = 'fluid_temperature solid_temperature'
    property_name = fluid_solid_energy_exchange
    expression = '100*(solid_temperature-fluid_temperature)'
  []

  [inactive_well_sources]
    type = ADGenericConstantMaterial
    block = '1 2 3 11 13'
    prop_names = 'spe1_well_water_reference_component_source spe1_well_oil_reference_component_source spe1_well_free_gas_reference_component_source spe1_well_gas_reference_component_source'
    prop_values = '0 0 0 0'
  []
  [injector_relative_permeability]
    type = ADGenericConstantMaterial
    block = 11
    prop_names = 'injector_water_relative_permeability injector_oil_relative_permeability injector_gas_relative_permeability'
    prop_values = '0 0 1'
  []
  [injector]
    type = ADBlackOilPeacemanWellMaterial
    block = 11
    pressure_source = material
    water_pressure_name = spe1_oil_pressure_total
    oil_pressure_name = spe1_oil_pressure_total
    gas_pressure_name = spe1_oil_pressure_total
    mobility_source = relative_permeability_viscosity
    water_relative_permeability_name = injector_water_relative_permeability
    oil_relative_permeability_name = injector_oil_relative_permeability
    gas_relative_permeability_name = injector_gas_relative_permeability
    water_viscosity_name = benchmark_black_oil_water_viscosity
    oil_viscosity_name = benchmark_black_oil_oil_viscosity
    gas_viscosity_name = benchmark_black_oil_gas_viscosity
    water_fvf_name = benchmark_black_oil_water_formation_volume_factor
    oil_fvf_name = benchmark_black_oil_oil_formation_volume_factor
    gas_fvf_name = benchmark_black_oil_gas_formation_volume_factor
    solution_gas_oil_ratio_name = benchmark_black_oil_solution_gas_oil_ratio
    well_index = 2.8317755055348615e-12
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = injector_bhp_scalar
    injection_phase = gas
    target_surface_rate = -32.774128
    completion_reference_volume = 566336.9318400001
    water_surface_density = 1033.0307029866894
    oil_surface_density = 859.5507446467011
    gas_surface_density = 0.8537840978320755
    property_prefix = spe1_well
  []
  [producer]
    type = ADBlackOilPeacemanWellMaterial
    block = 13
    pressure_source = material
    water_pressure_name = spe1_oil_pressure_total
    oil_pressure_name = spe1_oil_pressure_total
    gas_pressure_name = spe1_oil_pressure_total
    mobility_source = relative_permeability_viscosity
    water_relative_permeability_name = black_oil_water_relative_permeability
    oil_relative_permeability_name = black_oil_oil_relative_permeability
    gas_relative_permeability_name = black_oil_gas_relative_permeability
    water_viscosity_name = benchmark_black_oil_water_viscosity
    oil_viscosity_name = benchmark_black_oil_oil_viscosity
    gas_viscosity_name = benchmark_black_oil_gas_viscosity
    water_fvf_name = benchmark_black_oil_water_formation_volume_factor
    oil_fvf_name = benchmark_black_oil_oil_formation_volume_factor
    gas_fvf_name = benchmark_black_oil_gas_formation_volume_factor
    solution_gas_oil_ratio_name = benchmark_black_oil_solution_gas_oil_ratio
    well_index = 2.8317755055348615e-12
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = producer_bhp_scalar
    target_surface_rate = 0.03680261456666667
    completion_reference_volume = 1415842.3296
    water_surface_density = 1033.0307029866894
    oil_surface_density = 859.5507446467011
    gas_surface_density = 0.8537840978320755
    property_prefix = spe1_well
  []
[]

[Kernels]
  [matrix_component_balance]
    type = ADMaterialPropertyResidual
    variable = matrix_reference_component_storage
    property = solid_reference_component_balance_residual
  []
  [matrix_momentum_x]
    type = ADReferenceSolidMomentum
    variable = ux
    component = 0
  []
  [matrix_momentum_y]
    type = ADReferenceSolidMomentum
    variable = uy
    component = 1
  []
  [matrix_momentum_z]
    type = ADReferenceSolidMomentum
    variable = uz
    component = 2
  []
  [mixture_gravity_x]
    type = ADReferenceVectorMaterialSourceTerm
    variable = ux
    component = 0
    source_name = mixture_gravity_force
  []
  [mixture_gravity_y]
    type = ADReferenceVectorMaterialSourceTerm
    variable = uy
    component = 1
    source_name = mixture_gravity_force
  []
  [mixture_gravity_z]
    type = ADReferenceVectorMaterialSourceTerm
    variable = uz
    component = 2
    source_name = mixture_gravity_force
  []
  [oil_conversion_insertion_momentum_x]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = ux
    component = 0
    conversion_rate = gas_phase_transformation_rate
    rate_scale = -1
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    reference_relative_velocity_name = oil_reference_relative_velocity
  []
  [oil_conversion_insertion_momentum_y]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = uy
    component = 1
    conversion_rate = gas_phase_transformation_rate
    rate_scale = -1
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    reference_relative_velocity_name = oil_reference_relative_velocity
  []
  [oil_conversion_insertion_momentum_z]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = uz
    component = 2
    conversion_rate = gas_phase_transformation_rate
    rate_scale = -1
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    reference_relative_velocity_name = oil_reference_relative_velocity
  []
  [gas_conversion_insertion_momentum_x]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = ux
    component = 0
    conversion_rate = gas_phase_transformation_rate
    rate_scale = 1
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    reference_relative_velocity_name = gas_reference_relative_velocity
  []
  [gas_conversion_insertion_momentum_y]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = uy
    component = 1
    conversion_rate = gas_phase_transformation_rate
    rate_scale = 1
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    reference_relative_velocity_name = gas_reference_relative_velocity
  []
  [gas_conversion_insertion_momentum_z]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = uz
    component = 2
    conversion_rate = gas_phase_transformation_rate
    rate_scale = 1
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    reference_relative_velocity_name = gas_reference_relative_velocity
  []
  [water_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = water_saturation
    enrichment = water_saturation_enrichment
    reference_component_storage_rate_name = benchmark_black_oil_water_reference_component_storage_rate
    reference_flux_name = water_reference_component_flux
    source_name = spe1_well_water_reference_component_source
  []
  [water_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = water_saturation_enrichment
    backbone = water_saturation
    reference_component_storage_rate_name = benchmark_black_oil_water_reference_component_storage_rate
    source_name = spe1_well_water_reference_component_source
  []
  [water_saturation_entropy_flux]
    type = ADReferenceComponentFluxTerm
    variable = water_saturation
    reference_flux_name = water_saturation_ev_reference_flux
  []
  [oil_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = oil_pressure
    enrichment = oil_pressure_enrichment
    reference_component_storage_rate_name = benchmark_black_oil_oil_reference_component_storage_rate
    reference_flux_name = oil_reference_component_flux
    source_name = spe1_well_oil_reference_component_source
  []
  [oil_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = oil_pressure_enrichment
    backbone = oil_pressure
    reference_component_storage_rate_name = benchmark_black_oil_oil_reference_component_storage_rate
    source_name = spe1_well_oil_reference_component_source
    # Fix only the redundant global P1/P0 decomposition; all constitutive
    # objects consume the reconstructed total pressure.
    anchor_coefficient = 1e-12
  []
  [gas_balance]
    type = ADEnrichedGalerkinScalarBalance
    # The stock-tank-gas conservation equation remains active when S_g is at
    # its lower bound.  R_s and S_g use the same continuous P1 parent space.
    variable = solution_gas_oil_ratio
    reference_component_storage_rate_name = benchmark_black_oil_gas_reference_component_storage_rate
    reference_flux_name = gas_reference_component_flux
    source_name = spe1_well_gas_reference_component_source
  []
  [free_gas_storage]
    type = ADReferenceMaterialStorageRateTerm
    variable = gas_saturation
    reference_storage_rate_name = benchmark_black_oil_free_gas_reference_component_storage_rate
  []
  [free_gas_transport]
    type = ADReferenceComponentFluxTerm
    variable = gas_saturation
    reference_flux_name = gas_reference_relative_mass_flux
  []
  [free_gas_well_source]
    type = ADReferenceComponentSourceTerm
    variable = gas_saturation
    reference_source_name = spe1_well_free_gas_reference_component_source
  []
  [free_gas_phase_conversion]
    type = ADReferenceComponentSourceTerm
    variable = gas_saturation
    reference_source_name = spe1_phase_transfer_gas_reference_component_source_0
  []
  [free_gas_enrichment_storage]
    type = ADReferenceMaterialStorageRateTerm
    variable = gas_saturation_enrichment
    reference_storage_rate_name = benchmark_black_oil_free_gas_reference_component_storage_rate
  []
  [free_gas_enrichment_well_source]
    type = ADReferenceComponentSourceTerm
    variable = gas_saturation_enrichment
    reference_source_name = spe1_well_free_gas_reference_component_source
  []
  [free_gas_enrichment_phase_conversion]
    type = ADReferenceComponentSourceTerm
    variable = gas_saturation_enrichment
    reference_source_name = spe1_phase_transfer_gas_reference_component_source_0
  []
  [gas_saturation_entropy_flux]
    type = ADReferenceComponentFluxTerm
    variable = gas_saturation
    reference_flux_name = gas_saturation_ev_reference_flux
  []
  [gas_phase_transformation_closure]
    type = ADMaterialPropertyResidual
    variable = gas_phase_transformation_rate
    property = spe1_phase_transfer_kinetic_residual_0
  []
  [tau_backbone_equation]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = tau
    property = tau_evolution_residual
  []
  [tau_enrichment_equation]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = tau_enrichment
    property = tau_evolution_residual
    anchor_coefficient = 1e-12
  []

  [fluid_internal_energy_storage]
    type = ADReferenceEnergyStorageTerm
    variable = fluid_temperature
    coefficient_name = fluid_energy_storage
  []
  [fluid_nonadvective_heat_transport]
    type = ADReferenceEnergyFluxTerm
    variable = fluid_temperature
    reference_flux_name = fluid_nonadvective_heat_flux
    scale = -1
  []
  [fluid_interphase_energy_exchange]
    type = ADReferenceEnergySourceTerm
    variable = fluid_temperature
    source_name = fluid_solid_energy_exchange
  []
  [fluid_phase_conversion_energy]
    type = ADReferenceEnergyConversionTransferWorkTerm
    variable = fluid_temperature
    generalized_transfer_work_names = 'oil_gas_component_generalized_transfer_work free_gas_component_generalized_transfer_work'
    current_component_source_names = 'spe1_phase_transfer_oil_current_component_source_0 spe1_phase_transfer_gas_current_component_source_0'
  []

  [solid_internal_energy_storage]
    type = ADReferenceEnergyStorageTerm
    variable = solid_temperature
    coefficient_name = solid_energy_storage
  []
  [solid_nonadvective_heat_transport]
    type = ADReferenceEnergyFluxTerm
    variable = solid_temperature
    reference_flux_name = solid_nonadvective_heat_flux
    scale = -1
  []
  [solid_interphase_energy_exchange]
    type = ADReferenceEnergySourceTerm
    variable = solid_temperature
    source_name = fluid_solid_energy_exchange
    scale = -1
  []
[]

[AuxKernels]
  [phase_transform_dissipation]
    type = ADMaterialRealAux
    variable = phase_transform_dissipation
    property = spe1_phase_transfer_reaction_power_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Bounds]
  [nonnegative_water_saturation]
    type = CoefficientBounds
    variable = water_saturation_bound
    bounded_variable = water_saturation
    bound_type = lower
    bound_value = 0
  []
  [nonnegative_water_saturation_enrichment]
    type = ConstantBounds
    variable = water_saturation_enrichment_bound
    bounded_variable = water_saturation_enrichment
    bound_type = lower
    bound_value = 0
  []
  [nonnegative_gas_saturation]
    type = CoefficientBounds
    variable = gas_saturation_bound
    bounded_variable = gas_saturation
    bound_type = lower
    bound_value = 0
  []
  [nonnegative_gas_saturation_enrichment]
    type = ConstantBounds
    variable = gas_saturation_enrichment_bound
    bounded_variable = gas_saturation_enrichment
    bound_type = lower
    bound_value = 0
  []
[]

[Dampers]
  [physical_saturation_simplex]
    type = SaturationSimplexGeneralDamper
    first_backbone = water_saturation
    second_backbone = gas_saturation
    first_enrichment = water_saturation_enrichment
    second_enrichment = gas_saturation_enrichment
    maximum_total_saturation = 0.9999999999
    fraction_to_boundary = 0.9
  []
[]

[BCs]
  [matrix_pin_x]
    type = DirichletBC
    variable = ux
    boundary = spe1_mechanics_pin_xyz
    value = 0
  []
  [matrix_pin_y]
    type = DirichletBC
    variable = uy
    boundary = 'spe1_mechanics_pin_xyz spe1_mechanics_pin_yz'
    value = 0
  []
  [matrix_bottom_normal_support]
    type = DirichletBC
    variable = uz
    # The deep horizontal face (z = 2567.94, exodus 'front') carries the
    # mixture weight.  The CartesianMeshGenerator name 'bottom' resolves to
    # the y = 0 vertical side wall, which would leave the geostatic column
    # unsupported at the base and produce a spurious O(100 m) initial
    # momentum residual on the deep face.
    boundary = front
    value = 0
  []
[]

[DGKernels]
  [water_saturation_physical_flux]
    type = ADUpwindReferenceComponentFluxDG
    variable = water_saturation_enrichment
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'zero_component_fraction zero_component_fraction benchmark_black_oil_water_component_mass_fraction_in_water'
  []
  [gas_saturation_physical_flux]
    type = ADUpwindReferenceComponentFluxDG
    variable = gas_saturation_enrichment
    phase_reference_relative_mass_flux_names = gas_reference_relative_mass_flux
    phase_component_mass_fraction_names = benchmark_black_oil_gas_component_mass_fraction_in_gas
  []
  [water_saturation_entropy_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = water_saturation_enrichment
    reference_flux_name = water_saturation_ev_reference_flux
    mobility_name = water_saturation_ev_mobility
    epsilon = -1
    sigma = 1e-2
  []
  [water_saturation_entropy_backbone_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = water_saturation
    enrichment = water_saturation_enrichment
    mobility_name = water_saturation_ev_mobility
    epsilon = -1
  []
  [gas_saturation_entropy_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = gas_saturation_enrichment
    reference_flux_name = gas_saturation_ev_reference_flux
    mobility_name = gas_saturation_ev_mobility
    epsilon = -1
    sigma = 1e-2
  []
  [gas_saturation_entropy_backbone_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = gas_saturation
    enrichment = gas_saturation_enrichment
    mobility_name = gas_saturation_ev_mobility
    epsilon = -1
  []
  [oil_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = oil_pressure_enrichment
    reference_flux_name = oil_reference_component_flux
    mobility_name = oil_darcy_mobility
    epsilon = -1
    sigma = 10
  []
  [oil_backbone_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = oil_pressure
    enrichment = oil_pressure_enrichment
    mobility_name = oil_darcy_mobility
    epsilon = -1
  []
[]

[ScalarKernels]
  active = ''
  [injector_control]
    type = BlackOilNodalWellControl
    variable = injector_bhp_scalar
    boundary = spe1_injector_completion_nodes
    pressure = oil_pressure
    surface_rate = injector_gas_surface_rate
    surface_productivity = injector_gas_surface_productivity
    target_surface_rate = -32.774128
    apply_bhp_limit = true
    bhp_limit_type = maximum
    bhp_limit = 62149342.24061635
  []
  [producer_control]
    type = BlackOilNodalWellControl
    variable = producer_bhp_scalar
    boundary = spe1_producer_completion_nodes
    pressure = oil_pressure
    surface_rate = producer_oil_surface_rate
    surface_productivity = producer_oil_surface_productivity
    target_surface_rate = 0.03680261456666667
    apply_bhp_limit = true
    bhp_limit_type = minimum
    bhp_limit = 6894757.293168
  []
[]

[Postprocessors]
  active = 'matrix_component_balance_l2 phase_volume_constraint_l2 gas_appearance_complementarity_l2 phase_transform_kinetic_residual_l2 tau_evolution_residual_l2 phase_transform_affinity_identity_l2 phase_transform_generalized_force_identity_l2 phase_transform_power_identity_l2 minimum_phase_transform_dissipation minimum_undersaturation_gap average_solid_reference_jacobian minimum_solid_reference_jacobian matrix_component_storage_rate_integral matrix_momentum_x_scaled_weak_residual_linf matrix_momentum_y_scaled_weak_residual_linf matrix_momentum_z_scaled_weak_residual_linf fluid_energy_scaled_weak_residual_linf solid_energy_scaled_weak_residual_linf ux_l2 uy_l2 uz_l2 average_oil_pressure average_water_saturation average_gas_saturation minimum_oil_saturation minimum_gas_saturation maximum_gas_saturation average_solution_gas_oil_ratio average_tau average_reconstructed_tau average_phase_transform_dissolved_mu average_phase_transform_free_mu average_phase_transform_affinity average_phase_transform_generalized_force average_gas_phase_transformation_rate average_fluid_temperature average_solid_temperature water_storage_rate_integral oil_storage_rate_integral gas_storage_rate_integral water_source_integral oil_source_integral gas_source_integral water_global_balance oil_global_balance gas_global_balance gas_saturation_1_1_1 gas_saturation_1_1_2 gas_saturation_1_1_3 gas_saturation_10_1_1 gas_saturation_10_1_2 gas_saturation_10_1_3 gas_saturation_10_10_1 gas_saturation_10_10_2 gas_saturation_10_10_3 gas_saturation_1_1_1_backbone gas_saturation_1_1_1_enrichment gas_saturation_1_1_2_backbone gas_saturation_1_1_2_enrichment gas_saturation_1_1_3_backbone gas_saturation_1_1_3_enrichment gas_saturation_10_1_1_backbone gas_saturation_10_1_1_enrichment gas_saturation_10_1_2_backbone gas_saturation_10_1_2_enrichment gas_saturation_10_1_3_backbone gas_saturation_10_1_3_enrichment gas_saturation_10_10_1_backbone gas_saturation_10_10_1_enrichment gas_saturation_10_10_2_backbone gas_saturation_10_10_2_enrichment gas_saturation_10_10_3_backbone gas_saturation_10_10_3_enrichment'
  [matrix_component_balance_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_component_balance_residual
    function = 0
  []
  [phase_volume_constraint_l2]
    type = ADMaterialScalarL2Error
    property = phase_volume_constraint_residual
    function = 0
  []
  [gas_appearance_complementarity_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_appearance_complementarity_residual
    function = 0
  []
  [phase_transform_kinetic_residual_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transfer_kinetic_residual_0
    function = 0
  []
  [tau_evolution_residual_l2]
    type = ADMaterialScalarL2Error
    property = tau_evolution_residual
    function = 0
  []
  [phase_transform_affinity_identity_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_affinity_identity_residual
    function = 0
  []
  [phase_transform_generalized_force_identity_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_generalized_force_identity_residual
    function = 0
  []
  [phase_transform_power_identity_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_power_identity_residual
    function = 0
  []
  [minimum_phase_transform_dissipation]
    type = ADElementExtremeMaterialProperty
    mat_prop = spe1_phase_transfer_reaction_power_0
    value_type = min
  []
  [minimum_undersaturation_gap]
    type = ADElementExtremeMaterialProperty
    mat_prop = benchmark_black_oil_undersaturation_gap
    value_type = min
  []
  [average_solid_reference_jacobian]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_reference_J
  []
  [minimum_solid_reference_jacobian]
    type = ADElementExtremeMaterialProperty
    mat_prop = solid_reference_J
    value_type = min
  []
  [matrix_component_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = solid_reference_component_storage_rate
  []
  [matrix_momentum_x_scaled_weak_residual_linf]
    type = DiscreteVariableResidualNorm
    variable = ux
    norm_type = l_inf
    include_scaling_factor = true
  []
  [matrix_momentum_y_scaled_weak_residual_linf]
    type = DiscreteVariableResidualNorm
    variable = uy
    norm_type = l_inf
    include_scaling_factor = true
  []
  [matrix_momentum_z_scaled_weak_residual_linf]
    type = DiscreteVariableResidualNorm
    variable = uz
    norm_type = l_inf
    include_scaling_factor = true
  []
  [fluid_energy_scaled_weak_residual_linf]
    type = DiscreteVariableResidualNorm
    variable = fluid_temperature
    norm_type = l_inf
    include_scaling_factor = true
  []
  [solid_energy_scaled_weak_residual_linf]
    type = DiscreteVariableResidualNorm
    variable = solid_temperature
    norm_type = l_inf
    include_scaling_factor = true
  []
  [fluid_energy_local_residual_l2]
    type = ADMaterialScalarL2Error
    property = fluid_energy_local_residual
    function = 0
  []
  [solid_energy_local_residual_l2]
    type = ADMaterialScalarL2Error
    property = solid_energy_local_residual
    function = 0
  []
  [fluid_energy_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = fluid_energy_storage_rate
  []
  [solid_energy_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = solid_energy_storage_rate
  []
  [fluid_energy_flux_divergence_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = fluid_energy_flux_divergence
  []
  [fluid_heat_flux_left]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = fluid_nonadvective_heat_flux
    component = 0
  []
  [fluid_heat_flux_right]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = fluid_nonadvective_heat_flux
    component = 0
  []
  [fluid_heat_flux_bottom]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = fluid_nonadvective_heat_flux
    component = 1
  []
  [fluid_heat_flux_top]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = fluid_nonadvective_heat_flux
    component = 1
  []
  [fluid_heat_flux_back]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = fluid_nonadvective_heat_flux
    component = 2
  []
  [fluid_heat_flux_front]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = fluid_nonadvective_heat_flux
    component = 2
  []
  [fluid_energy_boundary_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'fluid_heat_flux_right fluid_heat_flux_left fluid_heat_flux_top fluid_heat_flux_bottom fluid_heat_flux_front fluid_heat_flux_back'
    pp_coefs = '1 -1 1 -1 1 -1'
  []
  [solid_heat_flux_left]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = solid_nonadvective_heat_flux
    component = 0
  []
  [solid_heat_flux_right]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = solid_nonadvective_heat_flux
    component = 0
  []
  [solid_heat_flux_bottom]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = solid_nonadvective_heat_flux
    component = 1
  []
  [solid_heat_flux_top]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = solid_nonadvective_heat_flux
    component = 1
  []
  [solid_heat_flux_back]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = solid_nonadvective_heat_flux
    component = 2
  []
  [solid_heat_flux_front]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = solid_nonadvective_heat_flux
    component = 2
  []
  [solid_energy_boundary_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'solid_heat_flux_right solid_heat_flux_left solid_heat_flux_top solid_heat_flux_bottom solid_heat_flux_front solid_heat_flux_back'
    pp_coefs = '1 -1 1 -1 1 -1'
  []
  [solid_energy_flux_divergence_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = solid_energy_flux_divergence
  []
  [fluid_energy_source_power_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = fluid_energy_source_power
  []
  [solid_energy_source_power_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = solid_energy_source_power
  []
  [fluid_energy_external_work_power_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = fluid_energy_external_work_power
  []
  [solid_energy_external_work_power_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = solid_energy_external_work_power
  []
  [fluid_energy_conversion_power_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = fluid_energy_conversion_power
  []
  [solid_energy_conversion_power_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = solid_energy_conversion_power
  []
  [fluid_energy_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'fluid_energy_storage_rate_integral fluid_energy_boundary_flux fluid_energy_source_power_integral fluid_energy_external_work_power_integral fluid_energy_conversion_power_integral'
    pp_coefs = '1 1 -1 -1 1'
  []
  [solid_energy_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'solid_energy_storage_rate_integral solid_energy_boundary_flux solid_energy_source_power_integral solid_energy_external_work_power_integral solid_energy_conversion_power_integral'
    pp_coefs = '1 1 -1 -1 1'
  []
  [total_energy_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'fluid_energy_global_balance solid_energy_global_balance'
    pp_coefs = '1 1'
  []
  [equilibrated_oil_pressure_deviation_l2]
    type = ADMaterialScalarL2Error
    property = spe1_oil_pressure_total
    function = initial_pressure_vertex
  []
  [equilibrated_solution_gas_oil_ratio_deviation_l2]
    type = ElementL2Error
    variable = solution_gas_oil_ratio
    function = initial_solution_gas_oil_ratio
  []
  [equilibrated_water_saturation_deviation_l2]
    type = ADMaterialScalarL2Error
    property = spe1_water_saturation_total
    function = initial_water_saturation
  []
  [equilibrated_gas_saturation_deviation_l2]
    type = ADMaterialScalarL2Error
    property = spe1_gas_saturation_total
    function = initial_gas_saturation
  []
  [ux_l2]
    type = ElementL2Norm
    variable = ux
  []
  [uy_l2]
    type = ElementL2Norm
    variable = uy
  []
  [uz_l2]
    type = ElementL2Norm
    variable = uz
  []
  [average_oil_pressure]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_oil_pressure_total
  []
  [average_water_saturation]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_water_saturation_total
  []
  [average_gas_saturation]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_gas_saturation_total
  []
  [minimum_oil_saturation]
    type = ADElementExtremeMaterialProperty
    mat_prop = benchmark_black_oil_oil_saturation
    value_type = min
  []
  [minimum_gas_saturation]
    type = ADElementExtremeMaterialProperty
    mat_prop = spe1_gas_saturation_total
    value_type = min
  []
  [maximum_gas_saturation]
    type = ADElementExtremeMaterialProperty
    mat_prop = spe1_gas_saturation_total
    value_type = max
  []
  [average_solution_gas_oil_ratio]
    type = ElementAverageValue
    variable = solution_gas_oil_ratio
  []
  [average_tau]
    type = ElementAverageValue
    variable = tau
  []
  [average_reconstructed_tau]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_tau_total
  []
  [average_phase_transform_dissolved_mu]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_phase_transform_dissolved_gas_electrochemical_mu
  []
  [average_phase_transform_free_mu]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_phase_transform_free_gas_electrochemical_mu
  []
  [average_phase_transform_affinity]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_phase_transfer_affinity_0
  []
  [average_phase_transform_generalized_force]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_phase_transfer_generalized_conversion_coefficient_0
  []
  [average_gas_phase_transformation_rate]
    type = ElementAverageValue
    variable = gas_phase_transformation_rate
  []
  [average_fluid_temperature]
    type = ElementAverageValue
    variable = fluid_temperature
  []
  [average_solid_temperature]
    type = ElementAverageValue
    variable = solid_temperature
  []
  [water_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_water_reference_component_storage_rate
  []
  [oil_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_oil_reference_component_storage_rate
  []
  [gas_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_gas_reference_component_storage_rate
  []
  [water_reference_component_mass]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_water_reference_component_storage
  []
  [oil_reference_component_mass]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_oil_reference_component_storage
  []
  [gas_reference_component_mass]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_gas_reference_component_storage
  []
  [solid_reference_component_mass]
    type = ElementIntegralVariablePostprocessor
    variable = matrix_reference_component_storage
  []
  [water_source_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = spe1_well_water_reference_component_source
  []
  [oil_source_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = spe1_well_oil_reference_component_source
  []
  [gas_source_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = spe1_well_gas_reference_component_source
  []
  [water_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'water_storage_rate_integral water_source_integral'
    pp_coefs = '1 -1'
  []
  [oil_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'oil_storage_rate_integral oil_source_integral'
    pp_coefs = '1 -1'
  []
  [gas_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'gas_storage_rate_integral gas_source_integral'
    pp_coefs = '1 -1'
  []
  [injector_gas_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_gas_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [injector_cell_pressure]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_oil_pressure_total
  []
  [producer_cell_pressure]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_oil_pressure_total
  []
  [injector_water_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_water_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [injector_oil_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [producer_oil_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [producer_water_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_water_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [producer_gas_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_gas_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [field_gas_oil_ratio]
    type = ParsedPostprocessor
    expression = 'q_g/q_o'
    pp_names = 'producer_gas_surface_rate producer_oil_surface_rate'
    pp_symbols = 'q_g q_o'
  []
  [injected_gas_surface_rate]
    type = LinearCombinationPostprocessor
    pp_names = 'injector_gas_surface_rate'
    pp_coefs = '-1'
  []
  [injected_gas_surface_volume]
    type = ImplicitEulerTimeIntegratedPostprocessor
    value = injected_gas_surface_rate
  []
  [produced_oil_surface_volume]
    type = ImplicitEulerTimeIntegratedPostprocessor
    value = producer_oil_surface_rate
  []
  [produced_gas_surface_volume]
    type = ImplicitEulerTimeIntegratedPostprocessor
    value = producer_gas_surface_rate
  []
  [produced_water_surface_volume]
    type = ImplicitEulerTimeIntegratedPostprocessor
    value = producer_water_surface_rate
  []
  [gas_saturation_1_1_1_backbone]
    type = PointValue
    variable = gas_saturation
    point = '152.4 152.4 2540.508'
  []
  [gas_saturation_1_1_1_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '152.4 152.4 2540.508'
  []
  [gas_saturation_1_1_1]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_1_1_1_backbone gas_saturation_1_1_1_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [gas_saturation_1_1_2_backbone]
    type = PointValue
    variable = gas_saturation
    point = '152.4 152.4 2548.128'
  []
  [gas_saturation_1_1_2_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '152.4 152.4 2548.128'
  []
  [gas_saturation_1_1_2]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_1_1_2_backbone gas_saturation_1_1_2_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [gas_saturation_1_1_3_backbone]
    type = PointValue
    variable = gas_saturation
    point = '152.4 152.4 2560.32'
  []
  [gas_saturation_1_1_3_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '152.4 152.4 2560.32'
  []
  [gas_saturation_1_1_3]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_1_1_3_backbone gas_saturation_1_1_3_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [gas_saturation_10_1_1_backbone]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 152.4 2540.508'
  []
  [gas_saturation_10_1_1_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '2895.6 152.4 2540.508'
  []
  [gas_saturation_10_1_1]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_10_1_1_backbone gas_saturation_10_1_1_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [gas_saturation_10_1_2_backbone]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 152.4 2548.128'
  []
  [gas_saturation_10_1_2_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '2895.6 152.4 2548.128'
  []
  [gas_saturation_10_1_2]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_10_1_2_backbone gas_saturation_10_1_2_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [gas_saturation_10_1_3_backbone]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 152.4 2560.32'
  []
  [gas_saturation_10_1_3_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '2895.6 152.4 2560.32'
  []
  [gas_saturation_10_1_3]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_10_1_3_backbone gas_saturation_10_1_3_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [gas_saturation_10_10_1_backbone]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 2895.6 2540.508'
  []
  [gas_saturation_10_10_1_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '2895.6 2895.6 2540.508'
  []
  [gas_saturation_10_10_1]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_10_10_1_backbone gas_saturation_10_10_1_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [gas_saturation_10_10_2_backbone]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 2895.6 2548.128'
  []
  [gas_saturation_10_10_2_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '2895.6 2895.6 2548.128'
  []
  [gas_saturation_10_10_2]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_10_10_2_backbone gas_saturation_10_10_2_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [gas_saturation_10_10_3_backbone]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 2895.6 2560.32'
  []
  [gas_saturation_10_10_3_enrichment]
    type = PointValue
    variable = gas_saturation_enrichment
    point = '2895.6 2895.6 2560.32'
  []
  [gas_saturation_10_10_3]
    type = ParsedPostprocessor
    pp_names = 'gas_saturation_10_10_3_backbone gas_saturation_10_10_3_enrichment'
    pp_symbols = 'backbone enrichment'
    expression = 'backbone+enrichment'
  []
  [injector_gas_surface_productivity]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_control_surface_productivity
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
    outputs = none
  []
  [producer_oil_surface_productivity]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_control_surface_productivity
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
    outputs = none
  []
  [injector_bhp]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_effective_bottom_hole_pressure
  []
  [producer_bhp]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_effective_bottom_hole_pressure
  []
[]

[Preconditioning]
  [monolithic]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
    petsc_options_value = 'lu mumps'
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  line_search = bt
  # Three-hour steps keep each quadratic-Bernstein active-set transition
  # within the reduced-space VI Newton convergence basin.
  dt = 10800
  end_time = 86400
  # Retain enough accepted-step capacity for nonlinear cutback while ending
  # at the one-day initialization target.
  num_steps = 20
  # The higher-order saturation/EG graph reaches a repeatable O(1e-7)
  # assembled active-set floor after the Newton correction is at roundoff.
  # Independent component, volume, kinetic, and dissipation postprocessors
  # retain their stricter physical acceptance limits.
  # Keep the nonlinear residual comfortably below the independent 1e-6
  # component-balance history gate on the reference domain.
  nl_abs_tol = 1e-8
  # The large initial residual otherwise lets the relative criterion accept
  # before the global component balances reach their quantitative gates.
  nl_rel_tol = 1e-14
  nl_max_its = 40
  petsc_options_iname = '-snes_type'
  petsc_options_value = 'vinewtonrsls'
[]

[Outputs]
  csv = true
[]
