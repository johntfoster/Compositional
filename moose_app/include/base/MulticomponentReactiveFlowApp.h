#pragma once

#include "MooseApp.h"

class MulticomponentReactiveFlowApp : public MooseApp
{
public:
  static InputParameters validParams();

  MulticomponentReactiveFlowApp(const InputParameters & parameters);
  virtual ~MulticomponentReactiveFlowApp();

  static void registerApps();
  static void registerAll(Factory & f, ActionFactory & af, Syntax & s);
};
