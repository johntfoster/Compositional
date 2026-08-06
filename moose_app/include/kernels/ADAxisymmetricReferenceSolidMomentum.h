#pragma once

#include "ADKernel.h"

class Function;

/** Quasi-static axisymmetric solid momentum on the solid reference configuration. */
class ADAxisymmetricReferenceSolidMomentum : public ADKernel
{
public:
  static InputParameters validParams();

  ADAxisymmetricReferenceSolidMomentum(const InputParameters & parameters);

  void initialSetup() override;

protected:
  ADReal computeQpResidual() override;

  const unsigned int _component;
  const ADMaterialProperty<RankTwoTensor> & _first_piola_stress;
  const ADMaterialProperty<Real> & _solid_J;

  std::vector<const ADVariableValue *> _current_volume_force;
  const Function & _reference_body_force;
};
