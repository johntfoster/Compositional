#pragma once

#include "GeneralPostprocessor.h"

/** Integrates a postprocessor rate with the backward/implicit Euler rule. */
class ImplicitEulerTimeIntegratedPostprocessor : public GeneralPostprocessor
{
public:
  static InputParameters validParams();

  ImplicitEulerTimeIntegratedPostprocessor(const InputParameters & parameters);

  void initialize() override;
  void execute() override;
  Real getValue() const override;

protected:
  Real _value;
  const PostprocessorValue & _value_old;
  const PostprocessorValue & _rate;
};
