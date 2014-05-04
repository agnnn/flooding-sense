#ifndef MASTER_H
#define MASTER_H

typedef nx_struct CustomMsg {
  nx_uint8_t type;
  nx_uint16_t error;
  nx_uint16_t data;
  nx_uint16_t counter;
} CustomMsg_t;

enum {
  AM_RADIO_SENSE_MSG = 7,
};

#endif
