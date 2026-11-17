(* Demo's that demonstrate programs that are running on two cores

    1) Counter
    2) Switch

*)

hex
\ Demo-1: a counter between two cores
: CORE0         ( -- )                  \ Count on core-0 using two cores
    empty-fifo  1 fifo!
    begin
        rxf? if                         \ Data received?
            cr  fifo@ dup .  1+  fifo!  \ Yes, print, increase and sent back
        then  50 ms
    key? until
    0 fifo!  empty-fifo ;


\ Demo-1b: a counter between two cores
: CORE1         ( -- )              \ Display counter from core-0
    begin
        begin  10 us  rxf? until    \ Wait for data received
    fifo@ ?dup while                \ Read it, not zero?
        cr dup .  fifo!             \ Print it & sent back
    repeat  empty-fifo ;            \ Stop & clear on zero



\ Demo-2: Switch a program status on the other core
: BUTTON        ( -- )
    false  begin
    bootkey? if  invert dup fifo!  1 ms  then
        begin  dm 10 us  bootkey? until  dm 10 ms
    key? until  drop  empty-fifo ;


: RESPONSE      ( -- )
    empty-fifo  0  begin
        rxf? if
            fifo@ if  cr ." I am in mode-1 "
            else      cr ." I am in mode-2 "
            then
        then
        1+ dup 800 = if  dup -  ch . emit  then
        300 us
    key? until  drop  empty-fifo ;

\ End
