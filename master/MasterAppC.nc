#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "Master.h"

configuration MasterAppC
{
}
implementation {

  components MainC, MasterC;
  components new TimerMilliC();

  // Mote to mote comm
  components ActiveMessageC;
  components new AMSenderC(AM_RADIO_SENSE_MSG);
  components new AMReceiverC(AM_RADIO_SENSE_MSG);

  components PrintfC;
  components SerialStartC;

  MasterC.Boot -> MainC;
  MasterC.Timer -> TimerMilliC;

  MasterC.AMSend -> AMSenderC;
  MasterC.Packet -> AMSenderC;
  MasterC.Receive -> AMReceiverC;
  MasterC.RadioControl -> ActiveMessageC;
  MasterC.AMPacket -> AMSenderC;
}
