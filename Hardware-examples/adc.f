(* Small example on how to use the Analog-Digital-Converter W.O. 2023/2026

More on ADC chapter 12.4 page 1066 ff

*)

hex
400A0000 constant ADC-CS            \ ADC Control and Status
400A0004 constant ADC-RESULT        \ Result of most recent ADC conversion

: ADC           ( +n -- u )
    4 umin >r  3 adc-cs !           \ Enable ADC and temperature sensor
    r@ 4 < if                       \ Normal GPIO?
        80 r@ dm 26 + pads!         \ Yes, disable digital-IO
    then
    begin  100 adc-cs bit** until   \ Wait for READY flag
    r> 0C lshift  7 or adc-cs !     \ Start conversion on channel +n
    begin  100 adc-cs bit** until   \ Wait for READY flag
    adc-result @ ;                  \ Fetch conversion result

: .ADC          ( +n -- )
    base @ >r  decimal              \ Show in decimal
    adc  dup .                      \ Show raw voltage
    dm 806 dm 1000 */               \ Convert to millivolt
    0 <# # # # ch , hold #s #> type \ Print out
    ." V "  r> base ! ;

: ADC-DEMO      ( -- )
    begin  cr 0 .adc  80 ms key? until ;

\ End
