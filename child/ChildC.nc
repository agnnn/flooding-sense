#include "Timer.h"
#include "printf.h"

module ChildC
{
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer0;
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
  message_t self_sense_packet, child_sense_packet, bcast_packet;
  bool locked = FALSE;
  uint16_t counter;

  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t err) { }
  event void RadioControl.stopDone(error_t err) { }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    if (len != sizeof(CustomMsg_t)) {
      return msg;
    } else {
      CustomMsg_t* rsm = (CustomMsg_t*)payload;
      CustomMsg_t* bcast_msg;
      CustomMsg_t* child_sense_msg;

      uint8_t type = rsm->type;
      // If broadcast message
      if (type == 0) {
        // If already received this broadcast message, discard
        if (rsm->counter <= counter) {
          return msg ;
        }

        // Update this as the most recent BCAST msg,
        // and also the sender as the parent
        counter = rsm->counter;
        parent_node = call AMPacket.source(msg);

        // Rebuild broadcast package and send
        bcast_msg = (CustomMsg_t*)call Packet.getPayload(&bcast_packet, sizeof(CustomMsg_t));
        bcast_msg->type = rsm->type;
        bcast_msg->counter = counter;
        bcast_msg->forwarded = TRUE;
        if (call AMSend.send(AM_BROADCAST_ADDR, &bcast_packet, sizeof(CustomMsg_t)) == SUCCESS) {
          locked = TRUE;
        }

        // Blink leds green as we received a BCAST msg,
        // but also red if this was a forwarded BCAST msg
        call Leds.led1Toggle();
        if (rsm->forwarded) { call Leds.led0Toggle(); }

        // Now, wait 0.2s to avoid race conditions and send back our sense data
        call Timer0.startOneShot(200);

      // Child sense message
      } else {
        call Leds.led2Toggle();

        // Rebuild child's sense package and forward to parent
        child_sense_msg = (CustomMsg_t*)call Packet.getPayload(&child_sense_packet, sizeof(CustomMsg_t));
        child_sense_msg->type = rsm->type;
        child_sense_msg->nodeid = rsm->nodeid;
        child_sense_msg->data = rsm->data;
        child_sense_msg->counter = rsm->counter;
        if (call AMSend.send(parent_node, &child_sense_packet, sizeof(CustomMsg_t)) == SUCCESS) {
          locked = TRUE;
        }
      }
      return msg;
    }
  }

  // Read sense data and send to parent
  event void Timer0.fired() {
    call Read.read();
  }

  event void Read.readDone(error_t result, uint16_t data) {
    CustomMsg_t* rsm;
    rsm = (CustomMsg_t*)call Packet.getPayload(&self_sense_packet, sizeof(CustomMsg_t));
    rsm->type = 1;
    rsm->nodeid = TOS_NODE_ID;
    rsm->data = data;
    if (call AMSend.send(parent_node, &self_sense_packet, sizeof(CustomMsg_t)) == SUCCESS) { locked = TRUE; }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&self_sense_packet == msg ||
        &bcast_packet == msg ||
        &child_sense_packet == msg) {
      locked = FALSE;
    }
  }
}
