(* PIO example program generated with the EXPORT function

For use with the 'piobase.f' base file

Starts flashing when it's loaded

*)

need piobase\     ( Load the piobase.f file first )

hex
: PIO-PROG  ( -- )
    00000000 50200000 !
    0001F000 502000CC !
    14000000 502000DC !
    61A80000 502000C8 !
    14000320 502000DC !
    08000320 502000DC !
    00000006 400280CC !
    00000006 400280D4 !
    0000E083 50200048 !
    0001F080 502000CC !
    0000FF03 5020004C !
    0000FF5F 50200050 !
    0000BF21 50200054 !
    0000FF00 50200058 !
    00001F83 5020005C !
    00005080 502000CC !
    00000000 502000D8 !
\ Activate program on current clock setting
    0 =pio
    dm 6000  0 set-freq
    1 0 sm-on ;

pio-prog

' pio-prog  to app
shield FLASH\  ( freeze )
