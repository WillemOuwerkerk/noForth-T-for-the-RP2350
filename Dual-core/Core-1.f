(* Let core-1 on RP2350 run it's own code

Primitives for activating CORE-1 from CORE-0

\ PSM_BASE = 40018000 ( Power-on State Machine )
40018000 = FRC_OFF
40018004 = FRC_OFF
40018008 = WDSEL
4001800C = DONE

\ Watchdog reset = 400D8000
00 = CTRL
04 = LOAD

\ TICKS timer is a separate unit
0C 4 ticks  \ Start the watchdog TICK timer on 1 µs

\ SIO base = D0000000
50 = FIFO status register
54 = FIFO write
58 = FIFO read

: RESET0    ( -- )              \ Reset core 0  (48 bytes)
    0800000 40018008 **bis      \ Allow a WD reset of core-0
    1F bitmask 400D8000 **bis ; \ Force reset
: RESET1    ( -- )              \ Reset core 1  (48 bytes)
    1000000 40018008 **bis      \ Allow a WD reset of core-1
    1F bitmask 400D8000 **bis ; \ Force WD reset

When a WFE instruction is executed the current drops about
0,2mA to 2,5mA depending on the used PLL frequency!

\ Reset core-1
create RESET1 ( -- )      \ 26 bytes
    40018008 ,          \ HOP = PSM_BASE+08 = WDCEL - Watchdog reset selection
    400D8000 ,          \ DAY = WATCHDOG_BASE - Watchdog control register
    01000000 ,          \ SUN = Reset core-1 pattern
code>
    w  { hop day sun } ldm, \ Read pool
    sun  hop ) str,     \ Store core-1 reset
    sun 7 # lsls,       \ Make force reset bit
    sun  day ) str,     \ Activate force reset bit
    next,
end-code

\ Reset core-1
create RESET1 ( -- )      \ 26 bytes
    40018000 ,          \ HOP = PSM_BASE+08 = WDCEL - Watchdog reset selection
    01000000 ,          \ DAY = Reset core-1 pattern
code>
    w  { hop day } ldm, \ Read pool
    day  hop 4 #) str,  \ Store core-1 reset
    begin,
        sun  hop 0C #) ldr,
        sun day ands,
        sun day cmp,
    =? no until,
    sun sun eors,
    sun  hop 4 #) str,
    next,
end-code

\ Reset core-1
create RESET1 ( -- )      \ 26 bytes
    40018000 ,          \ HOP = PSM_BASE+08 = WDCEL - Watchdog reset selection
    01000000 ,          \ DAY = Reset core-1 pattern
code>
    w  { hop day } ldm, \ Read pool
    day  hop 4 #) str,  \ Store core-1 reset
    dsb,
    day  hop ) str,
    begin,
        sun  hop 0C #) ldr,
        sun day ands,
        sun day cmp,
    =? until,
    next,
end-code

*)

v: extra definitions
\ Reset core-1
create RESET1 ( -- )      \ 26 bytes
    40018008 ,          \ HOP = PSM_BASE+08 = WDCEL - Watchdog reset selection
    400D8000 ,          \ DAY = WATCHDOG_BASE - Watchdog control register
    01000000 ,          \ SUN = Reset core-1 pattern
code>
    w  { hop day sun } ldm, \ Read pool
    sun  hop ) str,     \ Store core-1 reset
    sun 7 # lsls,       \ Make force reset bit
    sun  day ) str,     \ Activate force reset bit
    next,
end-code

\ : FTX?          ( -- f )    2 D000,0050 bit** 0<> ;
\ : FRX?          ( -- f )    1 D000,0050 bit** 0<> ;
create FRX?       ( -- f )
    D000,0050 ,
code>
    day 1 # movs,       \ 1 - Fifo RX? bit
    tos sp -) str,      \ 3 - Save TOS
    w  w ) ldr,         \ 2 - Read addr. fifo status to W
    tos w ) ldr,        \ 2 - Read fifo status to TOS
    tos day ands,       \ 2 - Test it
    =? no if,           \ 2 - Not zero?
        tos day day subs.mv, \ 1+1 - Build true flag
        tos tos mvns,
    then,
    next,               \ 6
end-code
create FTX?       ( -- f )
    D000,0050 ,
code>
    day 2 # movs,       \ Fifo TX? bit
    ' frx? @ 2 + 77 again,
end-code

v: extra definitions
\ Send data to core-1
create FIFO!      ( x -- )
    D0000050 ,          \ FIFO status register
code>
    w  w ) ldr,
    sun 2 # movs,
    begin,
        hop  w ) ldr,   \ Read status
        hop sun ands,
    =? no until,        \ Space for TX
    tos  w 4 #) str,
    sev,                \ Set event
    sp { tos } ldm,
    next,
end-code

\ Read data from core-1
create FIFO@      ( -- x )
    D0000050 ,          \ FIFO status register
code>
    w  w ) ldr,
    begin,
        hop  w ) ldr,   \ Read status
        sun 1 # movs,
        hop sun ands,
    =? while,           \ Received on RX
        wfe,            \ Wait for event
    repeat,
    tos  sp -) str,
    tos  w 8 #) ldr,    \ Read FIFO
    next,
end-code

: EMPTY-FIFO        ( -- )  \ Empty incoming FIFO completely
    begin  frx? while  fifo@ drop  repeat ;

v: inside also definitions
\ Send & verify a command to core-1 in one word
: >CMD?         ( cmd -- f )    dup fifo!  fifo@ = ;

v: extra definitions
\ Start assembly code routine on core-1
\ Core-1 access sequence: 0, 0, 1, vectortable, sp, pc
: BOOT1         ( code-addr -- )
    hx 0C 4 ticks           \ Clock to watchdog
    1 or >r  reset1         \ Set thumb bit & reset core-1
    begin  begin  begin  begin  begin  begin
        empty-fifo          \ Clear incoming FIFO
    0 >cmd? until           \ Start with access sequence, succeed?
    0 >cmd? until           \ Second step, succeed?
    1 >cmd? until           \ Third step, succeed?
    20000000 >cmd? until    \ Sent interrupt table for core-1, succeed?
    tib/ 100 + >cmd? until  \ Sent stack pointer for core-1, succeed?
    r@ >cmd? until  rdrop ; \ Sent core-1 PC address, succeed?

v: fresh
\ shield CORE\  freeze

\ End
