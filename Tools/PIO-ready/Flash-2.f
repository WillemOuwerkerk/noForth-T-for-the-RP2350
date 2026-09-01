(* PIO example program generated with the EXPORT function

For use with the 'piobase.f' base file

FLASH   - LED on GPIO25 flashes
LED-ON  - LED continue on
LED-OFF - LED off
TEMPO   - Uses numbers from 7D0 and higher

*)

need piobase\     ( Load the piobase.f file first )

hex
: TOGGLE1   \ GPIO-25 LED control
    00000000 50200000 !
    0001F000 502000CC !
    014D5500 502000C8 !
    4001F000 502000CC !
    54006800 502000DC !
    48006B20 502000DC !
    00000006 400280CC !
    00000006 400280D4 !
    0000E083 50200048 !
    00000001 5020004C !
    4001F100 502000CC !
    0000FF01 50200050 !
    0000E75F 50200054 !
    0000A721 50200058 !
    0000A721 5020005C !
    0000A721 50200060 !
    0000A721 50200064 !
    0000E700 50200068 !
    00000784 5020006C !
    40009100 502000CC !
    00000000 502000D8 !
\ Activate program on current clock setting
    0 =pio
    dm 6000  0 set-freq
    1 0 sm-on ;

toggle1

: FLASH    2 0 exec-opc ;                   \ Jump to address 2, start flasher
: LED-OFF  1 0 exec-opc  E000 0 exec-opc ;  \ Pin 25 off, jump to wait loop
: LED-ON   1 0 exec-opc  E001 0 exec-opc ;  \ Pin 25 on, jump to wait loop
: TEMPO    dm 500 max  0 set-freq  flash ;  \ Change flasher frequency

: START     ( -- )      toggle1  1 ms  flash ;
' start  to app

shield TOGGLE\  ( freeze )
