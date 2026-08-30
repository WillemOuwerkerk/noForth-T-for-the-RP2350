\ Print the 5 cells noForth-T configuration

\ Try to convert an address to name field address, version-2
hex  v: fresh inside also  definitions
noname      ( a1 -- a2 )    \ <SKIP-FF
    3B012503 ,  2EFF781E ,  3D01D102 ,
    3B01D1F9 ,  CA10C804 ,  FFFF46A7 ,
end-code  >r

: >NFA      ( a -- nfa | 0 )    \ >NFA returns 0 when no header is found!
    dup 3 and 0= if                     \ 32aligned?
        dup origin chere within         \ In noForth code area?
        if  [ r> compile, ]  false      \ Skip-FF count
            begin
                over c@ ch ! 7F within  \ Char. range = 21 7F
            while
                true /string
            dup BL = until              \ String too long?
            then  ( a +n )
            ?dup if
                over c@  7F and  = if   \ count ok?
                    dup 1 and if        \ nfa odd -> ok
                    dup 1- cell- @
                    over < and exit     \ Link pointing backwards?
                then
        then then then
    then  drop false ;

: .CLK      ( -- )          \ Show current clock frequency
    max-clk @                   \ Used PLL clock in MHz
    40010040 @ h-h dm 1000 *    \ Read & scale fractional CLK_SYS_DIV
    swap  dm 1000 10000 */ +  / \ Scale fractional part and add to whole part
    0 <# # # # ch , hold #s #> type ."  MHz " ;


V: fresh inside
: .CFG      ( -- )
    base @  decimal                         \ Print in decimal
    MAX-CLK @+ dm 1,000,000 /               \ Calculate PLL clock in MHz
    cr ." PLL clock = "  dup u.  ." MHz, "  \ Show PLL clock
    ." SYS_CLK = " .clk                     \ Show system clock (CPU, etc.)
    cr ." Peripheral clock = "              \ Show PERI_CLK in MHz
    swap cell+ c@ / u.  ." MHz "
    0 cfg @+  b-b 2>r                       \ Read LED & S? GPIO numbers and save
    &config ['] noop = if                   \ Is it the default configuration?
        @+  cr ." UART-" 40070000 -  0F rshift . \ Yes, show used UART number
    else
        @+ drop cr ." USB-CDC "             \ No, show USB data
    then
    @+    ." at "  u.  ." Baud "            \ and baudrate
    r>    cr ." The LED is connected to GPIO"  . \ LED GPIO number
    r>    cr ." S? is on GPIO"  .           \ S? GPIO number
    @+    ." & GPIO-address " hex u.        \ S? Port address
    @+    cr me count type                  \ Show name of this system
    drop  ." , runs on core " D0000000 @ .  \ and on which core it runs
    @     cr ." Config extension word = " >nfa count type \ Show extended configuration
    base ! ;                                \ Restore original base

v: fresh
.cfg

\ End ;;;
