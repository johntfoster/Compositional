#pragma once

#include "GeneralDamper.h"

/**
 * Limit Newton updates so two reconstructed CG/EG saturations remain
 * nonnegative and their sum remains below its upper bound.  Matching
 * Bernstein coefficients make these coefficientwise conditions sufficient
 * throughout each element.
 */
class SaturationSimplexGeneralDamper : public GeneralDamper
{
public:
  static InputParameters validParams();

  SaturationSimplexGeneralDamper(const InputParameters & parameters);

protected:
  Real computeDamping(const NumericVector<Number> & solution,
                      const NumericVector<Number> & update) override;

  const unsigned int _first_backbone_number;
  const unsigned int _second_backbone_number;
  const unsigned int _first_enrichment_number;
  const unsigned int _second_enrichment_number;
  const Real _maximum_total_saturation;
  const Real _fraction_to_boundary;
};
