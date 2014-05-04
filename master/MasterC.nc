#include "Timer.h"
#include "printf.h"

module MasterC
{
  uses {
    interface Boot;
    interface Timer<TMilli>;

    interface AMSend;
    interface Packet;
    interface Receive;
    interface SplitControl as RadioControl;
    interface AMPacket;
  }
}
implementation {
  message_t packet;
  bool locked = FALSE;

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call Timer.startPeriodic(2000);
    }
  }
  event void RadioControl.stopDone(error_t err) {}

  event void Timer.fired() {
    if (locked) {
      return;
    }
    else {
      radio_sense_msg_t* rsm;

      rsm = (radio_sense_msg_t*)call Packet.getPayload(&packet, sizeof(radio_sense_msg_t));
      if (rsm == NULL) {
        return;
      }
      // rsm->error = result;
      // rsm->data = data;
      printf("Requesting data\n");
      printfflush();
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_sense_msg_t)) == SUCCESS) {
        locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    am_addr_t src = call AMPacket.source(msg);

    // If gone wrong
    if (len != sizeof(radio_sense_msg_t)) {
      return msg;
    } else {
      radio_sense_msg_t* rsm = (radio_sense_msg_t*)payload;
      uint16_t val = rsm->data;

      printf("Source: %d\n", src);
      printf("Data: %d\n", val);
      printfflush();

      return msg;
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&packet == msg) {
      locked = FALSE;
    }
  }
}
