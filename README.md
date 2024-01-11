# DSP tools 

## Composition

*   CORDIC (atan/abs/div) .sv modules
    1.  Customizable accurancy/number of stages
    2.  Python script for generation atan table file

*   Numerically controlled oscillator (NCO) .sv modules with adjustable/zero carrier frequency
    1.  Customizable input phase/sin/cos width
    2.  Customizable system/carrier frequency 
    3.  Python script for generation sin table file

*   Table oscillator .sv module
    1.  Customizable sin/cos width
    2.  Python script for generation sin table file

*   PID-controller .sv module
    1.  Customizable input phase/output pid value width
    2.  Customizable Kp, Ki, Kd, max(Ki*int(e(t)dt))

## Repository structure

*   [pyModel](./pyModel/)   - python model of PID controller
*   [src](./src/)           - .sv source files
*   [tb](./tb/)             - test bench for modules