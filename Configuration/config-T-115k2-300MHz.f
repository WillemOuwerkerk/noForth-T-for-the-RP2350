(* Changing the configuration of noForth T solo & duo

    0 CFG  = Switch S? & LED & clock frequency in 10kHz steps
    1 CFG  = Used UART address
    2 CFG  = Baudrate in bits per second
    3 CFG  = GPIO input address register
    4 CFG  = Boot method

    GROW   = Resize noForth with the number of bytes from the stack

Valid data for these parameters are:
    Clock       = 48 MHz to 480 MHz the max. is the selected PLL output freq.
    Uart        = Used UART address
    Baudrate    = Any baudrate like 9600, 115200 until 921600 was tested ok
    S? pin      = GPIO 24, but any free GPIO pin will do
    S? address  = GPIO input address register
    Boot        = 0 = noForth t solo
                  1/-1 = noForth t duo

    FREEZE   = Save bootup image
    FREEZE2  = Save spare image
    COLD     = (Re)load bootup image
    COLD2    = (Re)load spare image

*)

decimal

24 25 b+b 30000 h+h 0 cfg ! \ Set switch I/O-bit & led & frequency in 10kHz steps

hx 40070000         1 cfg ! \ Default UART or UART1 = 40078000

115200              2 cfg ! \ Baudrate is 115k2

hx D0000004         3 cfg ! \ GPIO input address register

4 cfg @ abs         4 cfg ! \ (Re)start the second image, if any

hex  config                 \ Test new configuration

\ freeze        \ Save new configuration, boots at startup & when you type COLD
\ freeze2       \ Save as spare system, boots when you type COLD2

\ End
