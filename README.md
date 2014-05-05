## How it works

Every two seconds the master node sends a broadcast message requesting sense data

A child mote receiving from the master:

1. Sets the master as the parent;
2. Updates its counter to reflect the most recent broadcast request;
2. Forwards this broadcast message to its neighboards (another broadcast);
3. The green led is toggled;
4. The sense data is read;
5. The sense data is transmitted back to the parent;

A child mode receiving the broadcast from a child mote:

1. Checks if this broadcast has been received before;
2. a) If it has, discards and exit; b) If it hasn't, continues;
3. Sets the child that transmitted the broadcast as the parent;
4. Forwards this broadcast message to its neighboards (another broadcast);
5. Both the green and the red leds are toggled;
6. The sense data is read;
7. The sense data is transmitted back to the parent;

A child mode receiving a sense message from a child mote:

1. Toggles the yellow led;
2. Send the message, tagging it as a forwarded message, to the parent;

The master receiving sense message prints it to the screen.

## Compiling and Installing

> Master node
```bash
make iris install,0 mib520,/dev/ttyUSB0
```

> Child nodes
```bash
SENSORBOARD=mda100 make iris install,[1,2] mib520,/dev/ttyUSB0
```

## Listening

Listen from the Master node

```bash
java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB1:iris
```

