#include <Vc/Vc>
#include <Vc/cpuid.h>
#include <iostream>

int Vc_CDECL main()
{
  using Vc::CpuId;
  std::cout << "        cacheLineSize: " << CpuId::cacheLineSize() << '\n';
}
