#include "MulticomponentReactiveFlowApp.h"
#include "MooseMain.h"

int
main(int argc, char * argv[])
{
  return Moose::main<MulticomponentReactiveFlowApp>(argc, argv);
}
