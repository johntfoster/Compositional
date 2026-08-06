# Ideal-mixture neutral potential audit

Milestone 5 audited the neutral ideal-mixture potential implemented by
`ADIdealMixtureFluidEOSMaterial`.

For the reduced Helmholtz contribution

```text
rho_bar psi_mix = sum_i rho_i [mu_ref_i + R_mix theta log(eta_i)],
eta_i = rho_i / rho_bar,
rho_bar = sum_i rho_i,
```

the constituent-density derivative at fixed temperature, phase volume fraction,
solid kinematics, and all other constituent densities is

```text
d(rho_bar psi_mix) / d rho_alpha
  = mu_ref_alpha + R_mix theta log(eta_alpha).
```

The possible `+ R_mix theta` term from differentiating
`rho_alpha log(rho_alpha / rho_bar)` is canceled by the derivative of the
common `-rho_bar log(rho_bar)` contribution across all constituents. Therefore
the implemented neutral component potential

```text
psi_vol + p / rho_bar + mu_ref_alpha + R_mix theta log(eta_alpha)
```

is consistent with the stated reduced free energy convention. The material
rejects nonpositive mass fractions and rejects supplied mass fractions whose
sum differs from one beyond `mass_fraction_sum_tol`; it does not regularize
vanishing compositions.

The non-reference EOS tests check `rho_bar^2 d psi_vol / d rho_bar = p` at
`p = 2.5`, mass-fraction normalization, positive-composition potentials, and
the pressure identity residual.
