#include "Timer.h"
#include "printf.h"

module ChildC
{
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer0;
    //interface Timer<TMilli> as Timer1;
    interface Leds;
    interface Read<uint16_t>;

    interface AMSend;
    interface Packet;
    interface Receive;
    interface SplitControl as RadioControl;
    interface AMPacket;
  }
}
implementation {
  am_addr_t parent_node;
  message_t packet;
  bool locked = FALSE;
  uint16_t counter;

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t err) {}

  event void RadioControl.stopDone(error_t err) {}

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    if (len != sizeof(CustomMsg_t)) {
      return msg;
    } else {
      CustomMsg_t* rsm = (CustomMsg_t*)payload;

      uint8_t type = rsm->type;
      if (type == 0) {
        if (rsm->counter <= counter) {
          return msg ;
        }
        parent_node = call AMPacket.source(msg);
        call Leds.led1Toggle();
        if (call AMSend.send(AM_BROADCAST_ADDR, payload, sizeof(CustomMsg_t)) == SUCCESS) {
          locked = TRUE;
        }
        call Timer0.startOneShot(100);
      } else {
        call Leds.led2Toggle();
        if (call AMSend.send(parent_node, payload, sizeof(CustomMsg_t)) == SUCCESS) {
          locked = TRUE;
        }
      }
      return msg;
    }
  }

  event void Timer0.fired() {
    call Read.read();
  }

  event void Read.readDone(error_t result, uint16_t data) {
    // if (locked) {
    //  return;
    // }
    // else {
      CustomMsg_t* rsm;

      rsm = (CustomMsg_t*)call Packet.getPayload(&packet, sizeof(CustomMsg_t));
      if (rsm == NULL) {
        return;
      }
      rsm->type = 1;
      rsm->error = result;
      rsm->data = data;
      if (call AMSend.send(parent_node, &packet, sizeof(CustomMsg_t)) == SUCCESS) {
        locked = TRUE;
      }
    // }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&packet == msg) {
      locked = FALSE;
    }
  }
}
