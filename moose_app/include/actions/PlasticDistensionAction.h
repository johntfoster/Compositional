#pragma once

#include "Action.h"

/** Selects and creates either the tensor or scalar manuscript plastic-distension kernels. */
class PlasticDistensionAction : public Action
{
public:
  static InputParameters validParams();
  PlasticDistensionAction(const InputParameters & parameters);

  void act() override;
};
