(* GPIO

More on SIO chapter 2.3.1 page 27 ff
More on IO user bank chapter 2.19 page 235 ff

*)

hex
: BOOTKEY?  ( -- f )    \ f = true when the BOOTSEL key is pressed
     8000 4003001C **bis  10 us \ QSPI pin-SS disable output (OEOVER bitfield)
    20000 40030018 bit** 0=     \ Read boot key in GPIO_QSPI_SS_STATUS bit 17
     8000 4003001C **bic ;      \ QSPI pin-SS enable output 

D0000020 constant GPIO-OE           \ GPIO output enable
D0000010 constant GPIO-OUT          \ GPIO output value

: BLINK     ( -- )                  \ 1 Hz flashing led
    5 dm 25 gpio!                   \ Enable SIO on pin 25 
    dm 25 bitmask GPIO-OE **bis     \ Bit is output
    begin
        dm 25 bitmask GPIO-OUT **bix  200 ms \ Toggle LED
    bootkey? until                  \ Until the boot key was pressed
    dm 25 bitmask GPIO-OUT **bic ;  \ LED off

\ End
