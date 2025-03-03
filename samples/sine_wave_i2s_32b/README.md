# Raspberry Pi Pico sine_wave with 32bit I2S DAC

## Pin Assignment

## Pin Assignment
In addition to original connection

### Serial (CP2102 module)
| Pico Pin # | Pin Name | Function | CP2102 module |
----|----|----|----
|  1 | GP0 | UART0_TX | RXD |
|  2 | GP1 | UART0_RX | TXD |
|  3 | GND | GND | GND |

### Serial interface usage
* type '+' or '=' to increase volume
* type '-' to decrease volume
* type '[' to decrease left channel's frequency
* type ']' to increase left channel's frequency
* type '{' to decrease right channel's frequency
* type '}' to increase right channel's frequency