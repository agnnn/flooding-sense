#include "Timer.h"
#include "printf.h"

module ChildC
{
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
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
  message_t self_sense_packet;
  message_t child_sense_packet;
  message_t bcast_packet;
  bool locked = FALSE;
  uint16_t counter;
  CustomMsg_t* rcv_payload = NULL;

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
        if (rsm->counter <= counter) {
          return msg ;
        }
        counter = rsm->counter;
        parent_node = call AMPacket.source(msg);
        call Leds.led1Toggle();

        // Build broadcast package and send
        bcast_msg = (CustomMsg_t*)call Packet.getPayload(&bcast_packet, sizeof(CustomMsg_t));
        bcast_msg->type = rsm->type;
        bcast_msg->counter = counter;
        if (call AMSend.send(AM_BROADCAST_ADDR, &bcast_packet, sizeof(CustomMsg_t)) == SUCCESS) { locked = TRUE; }

        // Now, wait 0.2s and send back our sense data
        call Timer0.startOneShot(200);
      // Child sense message
      } else {
        call Leds.led2Toggle();

        // Rebuild child's sense package and forward to parent
        child_sense_msg = (CustomMsg_t*)call Packet.getPayload(&child_sense_packet, sizeof(CustomMsg_t));
        child_sense_msg->type = rsm->type;
        child_sense_msg->nodeid = rsm->nodeid;
        child_sense_msg->error = rsm->error;
        child_sense_msg->data = rsm->data;
        child_sense_msg->counter = rsm->counter;
        if (call AMSend.send(parent_node, &child_sense_packet, sizeof(CustomMsg_t)) == SUCCESS) { locked = TRUE; }

        //call Timer1.startOneShot(400);
      }
      return msg;
    }
  }

  // Read sense data and send to parent
  event void Timer0.fired() {
    call Read.read();
  }

  // Forward sense package to parent
  event void Timer1.fired() {
    // if (call AMSend.send(parent_node, rcv_payload, sizeof(CustomMsg_t)) == SUCCESS) {locked = TRUE; }
  }

  event void Read.readDone(error_t result, uint16_t data) {
    CustomMsg_t* rsm;

    rsm = (CustomMsg_t*)call Packet.getPayload(&self_sense_packet, sizeof(CustomMsg_t));
    if (rsm == NULL) {
      return;
    }
    rsm->type = 1;
    rsm->nodeid = TOS_NODE_ID;
    rsm->error = result;
    rsm->data = data;
    if (call AMSend.send(parent_node, &self_sense_packet, sizeof(CustomMsg_t)) == SUCCESS) { locked = TRUE; }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&self_sense_packet == msg) { locked = FALSE; }
  }
}
