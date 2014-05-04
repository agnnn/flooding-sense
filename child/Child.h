#ifndef CHILD_H
#define CHILD_H

typedef nx_struct radio_sense_msg {
  nx_uint16_t error;
  nx_uint16_t data;
} radio_sense_msg_t;

enum {
  AM_RADIO_SENSE_MSG = 7,
};

#endif
