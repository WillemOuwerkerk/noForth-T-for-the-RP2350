(* Booting the RP2350, only 64 bytes in total

    1) an UF2 block definition
        Minimal version:
            FFFFDED3  Magic number
            10210142  Boot ARM secure mode
            000001FF  This block is only one word long?
            00000000  Offset to next block (none in this case)
            AB123579  Magic number
    2) A noForth boot program in sector 0
    3) Starting at 0100 the image

*)

anew -targ
hex  also forth
vocskey

\ The system is entirely in RAM:
20000000        to MSTART  \ Start of binary
mstart 00000 +  to IVECS   \ 48 vectors & default code
mstart 000D0 +  to IVECS/  \ Temporary gap for .T code
mstart 000D0 +  to HOT     \ Uhere starts here
mstart 00000 +  to ORIGIN  \ HERE starts here !!!!
\ ... system ...
\ mstart 1F800 +  to BORDER  \ End of user dictionary
mstart 1F800 +  to FLYBUF  \ 400 bytes
mstart 1FC00 +  to FLYBUF/
mstart 1FE80 +  to R0      \ 280 bytes
mstart 1FF80 +  to S0      \ 100 bytes
mstart 1FF80 +  to TIB     \ 080 bytes
mstart 20000 +  to TIB/
mstart 20000 +  to BORDER  \ Systems end
mstart 80000 +  to RAMTOP  \ End of user RAM for image-0
20080000        to XRAM    \ Ram for background tasks, etc.

:::NOFORTH:::
trace

    40028068 ,          \ 00 SUN = IO_BANK0 GPIO25
    -1 ,                \ 04 DAY = Reset vector

image-def

\ ip  sp  w   tos hop day sun moon
\ R0  R1  R2  R3  R4  R5  R6  R7
\ Setting up a simple LED flasher for CORE-0
\ Using only CPU registers and one I/O-pin
\ More info on SIO_BASE from address 36/54 ff.
  chere 10000000 - ivecs cell+ vec! \ Install BOOT at second location in IVECS
\ Build data pointer
    w 1 # movs,                     \ Set 1 in W
    tos w 1C # lsls.mv,             \ Set data pointer in TOS = 1000,0000
    hop  tos ) ldr,                 \ Load pointers in one go
\ Configureer GPIO25 voor SIO (Functie 5)
    sp 5 # movs,                    \ enable SIO    
    sp  hop 64 #) str,              \ IO_BANK0 GPIO25, IP = 400280CC
\ PADS isolation off
    sp 5A # movs,                   \ Build 10000
    day w 10 # lsls.mv,             \ Calc. PADS control address
    hop day adds,
    sp  hop ) str,                  \ GPIO25 control address, IP = 40038068
\ Activate output, W = already 1
    w 19 # lsls,                    \ Set bit 25, W = 200,0000
    ip 0D # movs,                   \ Build SIO_BASE, IP = D000,0000
    ip 1C # lsls,
    w  ip 30 #) str,                \ GPIO_OE
\ Blink loop
    begin,
\ Led toggle
        w  ip 28 #) str,            \ GPIO_OUT_XOR
\ inline delay
        sp ip 0B # lsrs.mv,         \ Scale delay to ~ 1,700,000
        begin,  sp 1 # subs, =? until,
    again,

;;;NOFORTH;;;

( ) cr chere FF + 1FF00 and u.
( )    chere origin - u.
( ) CHERE  to ROMHERE
( ) make.bin 
( ) make.uf2 

\ End
