#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration SingleAppC
{
}
implementation {

  components MainC, SingleC;
  components new TimerMilliC();
  components PrintfC;
  components SerialStartC;
  components LedsC;
  // components new PhotoC() as Sensor;
  components new TempC() as Sensor;

  SingleC.Boot -> MainC;
  SingleC.Leds -> LedsC;
  SingleC.Timer -> TimerMilliC;
  SingleC.Read -> Sensor;
}
