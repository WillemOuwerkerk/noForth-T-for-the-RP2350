(* Read the state of the BOOTSEL button on the RP2350.
   This one pulls the "Chip Select" wire of the QSPI flash low.

   Disconnect the SPI memory logic, this is in the OEOVER field of the SS-pin,
   wait a little (10us) for the charge to settle, read button state
   and restore the QSPI state.

More on IO QSPI bank chapter 9.11.2 page 760 ff
Note the used GPIO_QSPI_SS_STATUS & GPIO_QSPI_SS_CTRL registers

*)

hex
: BOOTKEY?  ( -- f )    \ f = true when the BOOTSEL key is pressed
     8000 4003001C **bis  10 us \ QSPI pin-SS disable output (OEOVER bitfield)
    20000 40030018 bit** 0=     \ Read boot key in GPIO_QSPI_SS_STATUS bit 17
     8000 4003001C **bic ;      \ QSPI pin-SS enable output 

\ End
