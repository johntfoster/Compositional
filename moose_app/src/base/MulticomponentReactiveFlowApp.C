#include "MulticomponentReactiveFlowApp.h"
#include "AppFactory.h"
#include "Moose.h"
#include "MooseSyntax.h"
#include "SolidMechanicsApp.h"

InputParameters
MulticomponentReactiveFlowApp::validParams()
{
  InputParameters params = MooseApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

registerKnownLabel("MulticomponentReactiveFlowApp");

MulticomponentReactiveFlowApp::MulticomponentReactiveFlowApp(
    const InputParameters & parameters)
  : MooseApp(parameters)
{
  MulticomponentReactiveFlowApp::registerAll(_factory, _action_factory, _syntax);
}

MulticomponentReactiveFlowApp::~MulticomponentReactiveFlowApp() {}

void
MulticomponentReactiveFlowApp::registerAll(Factory & f, ActionFactory & af, Syntax & syntax)
{
  SolidMechanicsApp::registerAll(f, af, syntax);
  Registry::registerObjectsTo(f, {"MulticomponentReactiveFlowApp"});
  Registry::registerActionsTo(af, {"MulticomponentReactiveFlowApp"});
  registerSyntax("PlasticDistensionAction", "Physics/PlasticDistension/*");
}

void
MulticomponentReactiveFlowApp::registerApps()
{
  registerApp(MulticomponentReactiveFlowApp);
}

extern "C" void
MulticomponentReactiveFlowApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  MulticomponentReactiveFlowApp::registerAll(f, af, s);
}

extern "C" void
MulticomponentReactiveFlowApp__registerApps()
{
  MulticomponentReactiveFlowApp::registerApps();
}
