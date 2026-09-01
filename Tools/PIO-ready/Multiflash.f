(* PIO example programs generated with the EXPORT function

For use with the 'piobase.f' base file

WS2812  - Changes color all the time
FLASH   - LED on GPIO25 flashes
LED-ON  - LED continue on
LED-OFF - LED off

*)

need piobase\     ( Load the piobase.f file first )

hex
:  MULTI-FLASH  \ WS2812 on GPIO28 & LED on GPIO-25 & GPIO-26
    00000000 50200000 !
    0001F000 502000CC !
    002D0000 502000C8 !
    24007380 502000DC !
    00000006 400280E4 !
    00040000 502000D0 !
    0000E081 50200048 !
    0000A0E6 5020004C !
    00006024 50200050 !
    0000A027 50200054 !
    00000020 50200058 !
    0000A0C7 5020005C !
    00000000 50200060 !
    00000027 50200058 !
    0000E03F 50200064 !
    0000A0C1 50200068 !
    00000009 50200060 !
    0000E057 5020006C !
    00006021 50200070 !
    00001020 50200074 !
    00001000 50200078 !
    0000102D 50200074 !
    0000A021 5020007C !
    0000100E 50200078 !
    0000008A 50200080 !
    0000EF3F 50200084 !
    0000A0E1 50200088 !
    0000602C 5020008C !
    0000A027 50200090 !
    00000F53 50200094 !
    00000001 50200098 !
    00000000 502000D8 !
    00000001 50200000 !
    00000001 50200000 !
    0001F000 502000E4 !
    14000000 502000F4 !
    61A80000 502000E0 !
    14000320 502000F4 !
    04000320 502000F4 !
    00000006 400280CC !
    0000E081 5020009C !
    0000E001 502000A0 !
    00000017 502000A4 !
    0000EF01 502000A8 !
    0000EF5F 502000AC !
    0000AF21 502000B0 !
    0000AF21 502000B4 !
    0000EF00 502000B8 !
    00000F9A 502000BC !
    00000018 502000C0 !
    00000015 502000F0 !
\ Activate program on current clock setting
    0 =pio
    dm 3,333,333 0 set-freq
    dm 6000 1 set-freq
    1 0 sm-on  1 1 sm-on ;

multi-flash

: FLASH    18 1 exec-opc ;                  \ Jump to address 24, start flasher
: LED-OFF  17 1 exec-opc  E000 1 exec-opc ; \ Pin 25 & 26 off, jump to wait loop (address 23)
: LED-ON   17 1 exec-opc  F801 1 exec-opc ; \ Pin 25 & 26 on, jump to wait loop (address 23)

' multi-flash  to app
shield MULTI\   ( freeze )
