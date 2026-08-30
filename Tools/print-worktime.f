( .WORK print on time after a reset )

: .WORK     ( -- )
    base @ >r  decimal
    begin
        40100070 @ >r                       \ Read high 32-bits
        40100074 @  40100070 @              \ Read 64 bits time: low, high
    dup r> <> while                         \ High part changed?
        2drop                               \ Drop data & try again
    repeat
    dm 1000 um/mod  swap >r                 \ Milliseconds first
    dm 60 /mod  swap >r                     \ Seconds
    dm 60 /mod  swap >r                     \ Minutes
    dm 24 /mod  swap >r                     \ Hours
        0 <# ch d hold # # #> type space    \ Print days
    r>  0 <# ch h hold # # #> type space    \ Hours
    r>  0 <# ch m hold # # #> type space    \ Minutes
    r>  0 <# ch s hold # # #> type space    \ Seconds
    r>  0 <# # # # #> type ." ms "          \ Finally milliseconds
    r> base ! ;

\ End ;;;
