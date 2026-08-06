#pragma once

#include "AuxKernel.h"

/**
 * Set a constant PETSc VI bound on every coefficient of a scalar FE variable.
 *
 * MOOSE's stock BoundsBase currently supports nodal variables and element
 * constants only.  This object deliberately works from the libMesh DofMap so
 * higher-order families such as BERNSTEIN can be bounded coefficient-wise.
 */
class CoefficientBounds : public AuxKernel
{
public:
  static InputParameters validParams();

  CoefficientBounds(const InputParameters & parameters);

protected:
  virtual void initialSetup() override;
  virtual Real computeValue() override;

  enum class BoundType
  {
    UPPER,
    LOWER
  };

  const BoundType _bound_type;
  const Real _bound_value;
  MooseVariableFieldBase & _bounded_var;
  NumericVector<Number> & _bounded_vector;
};
