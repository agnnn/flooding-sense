#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "Child.h"

configuration ChildAppC
{
}
implementation {

  components MainC, ChildC;
  components new TimerMilliC() as Timer0;
  components LedsC;

  // Mote to mote comm
  components ActiveMessageC;
  components new AMSenderC(AM_RADIO_SENSE_MSG);
  components new AMReceiverC(AM_RADIO_SENSE_MSG);

  components PrintfC;
  components SerialStartC;

  components new PhotoC() as Sensor;

  ChildC.Boot -> MainC;
  ChildC.Timer0 -> Timer0;
  ChildC.Leds -> LedsC;
  ChildC.Read -> Sensor;

  ChildC.AMSend -> AMSenderC;
  ChildC.Packet -> AMSenderC;
  ChildC.Receive -> AMReceiverC;
  ChildC.RadioControl -> ActiveMessageC;
  ChildC.AMPacket -> AMSenderC;

}
