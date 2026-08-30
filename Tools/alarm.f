\ Defining word that supports all four alarm registers
\ Usage examples, interval = microseconds
\ dm 1000000 0 alarm ZERO  \ Define alarm-0 goes off each 10000 탎
\ dm 800000  3 alarm THREE \ Define alarm-3 goes off each 8000 탎
\ Example: zero ch A and emit  three ch B and emit  many

hex
400B0010 constant ALARM0    \ 00 04 08 0C   Four alarm cells
400B0020 constant ARMED     \ 01 02 04 08   Four armed flags
400B0028 constant TIMERAWL  \ Low part of 64-bits timer
: ALARM     ( interval alarm -- ) \ Define timer using the alarm function
    create                      \ (interval = microseconds)
        swap ,  3 umin          \ Alarm interval
        dup cells  alarm0 + ,   \ Used alarm
        bitmask ,               \ Bit masker
    does>   ( -- f )
        dup 2 cells + @         \ Read bit mask
        armed bit** 0= dup if   \ Alarm not enabled or triggered?
            drop  @+ timerawl @ +   \ Ok, calc. next alarm time,
            swap @ !  true  true    \ set it and leave true
        then  nip ;             \ Remove data address

dm 1000000 0 alarm ZERO  \ Define alarm-0 goes off each 10000 탎
dm 800000  3 alarm THREE \ Define alarm-3 goes off each 8000 탎

: TEST
    begin
        zero if  ch a emit  then
        three if  ch b emit else  ch . emit  then
        20 ms
    key? until ;
