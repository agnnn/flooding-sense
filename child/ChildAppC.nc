#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "Child.h"

configuration ChildAppC
{
}
implementation {

  components MainC, ChildC;
  // components new TimerMilliC();

  // Mote to mote comm
  components ActiveMessageC;
  components new AMSenderC(AM_RADIO_SENSE_MSG);
  components new AMReceiverC(AM_RADIO_SENSE_MSG);

  components PrintfC;
  components SerialStartC;

  components new PhotoC() as Sensor;

  ChildC.Boot -> MainC;
  // ChildC.Timer -> TimerMilliC;
  ChildC.Read -> Sensor;

  ChildC.AMSend -> AMSenderC;
  ChildC.Packet -> AMSenderC;
  ChildC.Receive -> AMReceiverC;
  ChildC.RadioControl -> ActiveMessageC;
  ChildC.AMPacket -> AMSenderC;
}
