\ Slow down clock on startup to 16 Mhz

dm 3 run pin





need .cfg






v: inside
: SLOW-DOWN     ( -- )
    begin  cell us  usb? until
    50 ms  dm 16,000 khz  .cfg ;

v: fresh
' slow-down to app 

freeze   cold
