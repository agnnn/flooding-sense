#include "Timer.h"
#include "printf.h"

module ChildC
{
  uses {
    interface Boot;
    // interface Timer<TMilli>;
    interface Read<uint16_t>;

    interface AMSend;
    interface Packet;
    interface Receive;
    interface SplitControl as RadioControl;
    interface AMPacket;
  }
}
implementation {
  am_addr_t src;
  message_t packet;
  bool locked = FALSE;

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t err) {}

  event void RadioControl.stopDone(error_t err) {}

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    src = call AMPacket.source(msg);

    call Read.read();

    // If gone wrong
    if (len != sizeof(radio_sense_msg_t)) {
      return msg;
    } else {
      radio_sense_msg_t* rsm = (radio_sense_msg_t*)payload;
      uint16_t val = rsm->data;

      return msg;
    }
  }

  event void Read.readDone(error_t result, uint16_t data) {
    if (locked) {
      return;
    }
    else {
      radio_sense_msg_t* rsm;

      rsm = (radio_sense_msg_t*)call Packet.getPayload(&packet, sizeof(radio_sense_msg_t));
      if (rsm == NULL) {
        return;
      }
      rsm->error = result;
      rsm->data = data;
      if (call AMSend.send(src, &packet, sizeof(radio_sense_msg_t)) == SUCCESS) {
        locked = TRUE;
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&packet == msg) {
      locked = FALSE;
    }
  }
}
