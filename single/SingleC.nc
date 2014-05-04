#include "Timer.h"
#include "printf.h"

module SingleC
{
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
    interface Read<uint16_t>;
  }
}
implementation {
  uint8_t counter = 0;

  // sampling frequency in binary milliseconds
  #define SAMPLING_FREQUENCY 1000

  event void Boot.booted() {
    call Timer.startPeriodic(SAMPLING_FREQUENCY);
  }

  event void Timer.fired() {
    printf("Read attempt #%u\n", counter);
    //printfflush();
    call Read.read();
    counter++;
  }

  event void Read.readDone(error_t result, uint16_t data) {
    if (result == SUCCESS){
      printf("Data: %u\n", data);
    } else {
      printf("Failed\n");
    }
    printfflush();
  }
}
