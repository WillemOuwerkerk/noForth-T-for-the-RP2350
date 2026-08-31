\ Slow down clock on startup to 16 Mhz

v: inside
: SLOW-DOWN     ( -- )      begin  cell us  usb? until  80 ms  dm 16,000 khz ;

v: fresh
' slow-down to app 
freeze   cold
