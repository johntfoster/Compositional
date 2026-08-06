#pragma once

#include "Material.h"

class ADReferenceSubsystemEnergyDiagnosticMaterial : public Material
{
public:
  static InputParameters validParams();
  ADReferenceSubsystemEnergyDiagnosticMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADVariableValue & _temperature_dot;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<Real> & _storage_coefficient;
  const ADMaterialProperty<Real> & _flux_divergence;
  std::vector<const ADMaterialProperty<Real> *> _current_sources;
  std::vector<Real> _source_scales;
  std::vector<const ADMaterialProperty<Real> *> _current_external_works;
  std::vector<Real> _external_work_scales;
  std::vector<const ADMaterialProperty<Real> *> _transfer_works;
  std::vector<const ADMaterialProperty<Real> *> _component_sources;
  ADMaterialProperty<Real> & _storage_rate;
  ADMaterialProperty<Real> & _flux_divergence_term;
  ADMaterialProperty<Real> & _source_power;
  ADMaterialProperty<Real> & _external_work_power;
  ADMaterialProperty<Real> & _conversion_power;
  ADMaterialProperty<Real> & _local_residual;
};
