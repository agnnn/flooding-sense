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
  message_t bcast_packet;
  bool locked = FALSE;
  uint16_t counter = 0;


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
    } else {
      CustomMsg_t* rsm;

      rsm = (CustomMsg_t*)call Packet.getPayload(&bcast_packet, sizeof(CustomMsg_t));
      if (rsm == NULL) {
        return;
      }
      rsm->type = 0;
      rsm->counter = counter;
      counter++;
      printf("Requesting data counter %u\n", counter);
      printfflush();
      //if (call AMSend.send(AM_BROADCAST_ADDR, &bcast_packet, sizeof(CustomMsg_t)) == SUCCESS) {
      if (call AMSend.send(AM_BROADCAST_ADDR, &bcast_packet, sizeof(CustomMsg_t)) == SUCCESS) {
        locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    am_addr_t src = call AMPacket.source(msg);
    if (len != sizeof(CustomMsg_t)) {
      return msg;
    } else {
      CustomMsg_t* rsm = (CustomMsg_t*)payload;
      uint8_t type = rsm->type;
      uint8_t nodeid = rsm->nodeid;
      uint16_t val = rsm->data;
      if (type == 1) {
        printf("Source: %d\n", nodeid);
        printf("Data: %d\n", val);
        printfflush();
      }
      return msg;
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&bcast_packet == msg) {
      locked = FALSE;
    }
  }
}
