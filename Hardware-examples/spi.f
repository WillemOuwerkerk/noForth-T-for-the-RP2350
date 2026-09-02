(* High level SPI-0 & 1 master primitives for RP2350

    SPI0-ON     ( clk +n -- )       - Activate SPI for port 0
    SPI0-I/O    ( b1 -- b2 )        - Send & receive on spi0
    SPI0-OUT    ( b -- )            - Send on spi0
    SPI0-IN     ( -- b )            - Receive on spi0
    SPI1-ON     ( clk +n -- )       - Activate SPI for port 1
    SPI1-I/O    ( b1 -- b2 )        - Send & receive on spi1
    SPI1-OUT    ( b -- )            - Send on spi1
    SPI1-IN     ( -- b )            - Receive on spi1
    LOOPBACK    ( f 0|1 -- )        - Enable/disable loopback mode on spi 0 or 1
    I/O         ( m gpio -- )       - Set GPIO-pin to mode m

    40080000    - SPI0_BASE
    40088000    - SPI1_BASE

SPI is chapter 12.3 from page 1047 ff

SPI connections on RP2350:
        RX  CS  CLK TX  Port
GPIO    00  01  02  03  SPI0
GPIO    04  05  06  07  SPI0
GPIO    08  09  10  11  SPI1
GPIO    12  13  14  15  SPI1
GPIO    16  17  18  19  SPI0

*)

v: inside also definitions
: KHZ>          ( khz -- div1 div2 )
    0 cfg @ dm 1,000 *  swap /                  \ Calculate divisor
    dup FF < if  7E and  0000  exit  then       \ 254 or smaller
    dup 6000 < if  19 /  1800  exit  then       \ 6000 or smaller
    dup dm 64770 < if  FA /  F900  exit  then   \ 64770 or smaller
    ?abort ;    \ Unable to calculate divider settings!

: 'SPI          ( 0|1 -- a )    \ Select SPI base address
    1 = 8000 and  40080000 + ;

: SPI-MASTER    ( khz 0|1 -- )
    'spi >r                 \ Select SPI hardware
    khz>  0007 or  r@ !     \ SSPCR0    Clock divisor, 8-bits data, motorola
    2 r@ cell+ **bic        \ SSPCR1    Disable SSE
    2 r@ cell+ !            \ SSPCR1    Synchronous master
    r> 10 + ! ;             \ SSPCPSR   clock prescaler

: SPI-SLAVE     ( khz 0|1 -- )
    'spi >r                 \ Select SPI hardware
    khz>  0007 or  r@ !     \ SSPCR0    Clock divisor, 8-bits data, motorola
    2 r@ cell+ **bic        \ SSPCR1    Disable SSE
    6 r@ cell+ !            \ SSPCR1    Synchronous slave
    r> 10 + ! ;             \ SSPCPSR   clock prescaler

v: extra definitions
: LOOPBACK  ( f 0|1 -- )    \ Loopback mode for spi-0 or 1 on/off
    'spi cell+ >r  1 and  r@ @ 0E and or r> ! ;

\ SPI-0 on GPIO 16 to 19  (rx, csn, sck, tx)
: SPI0-ON       ( khz -- )
    1 10 gpio!  1 11 gpio!  \ GPIO16 to 19 for SPI0
    1 12 gpio!  1 13 gpio!
    0 spi-master ;

: SPI0-I/O      ( b1 -- b2 )
    40080008 >r
    begin  2 r@ cell+ bit** until  r@ !
    begin  4 r@ cell+ bit** until  r> @ ;

: SPI0-OUT      ( b -- )        spi0-i/o drop ;
: SPI0-IN       ( -- b )        0 spi0-i/o ;


\ SPI-1 on GPIO10 to 13  (sck, tx, rx, scn)
: SPI1-ON       ( khz -- )
    1 0A gpio!  1 0B gpio!  \ GPIO10 to 13 for SPI1
    1 0C gpio!  1 0D gpio!
    1 spi-master ;

: SPI1-I/O      ( b1 -- b2 )
    40088008 >r
    begin  2 r@ cell+ bit** until  r@ !
    begin  4 r@ cell+ bit** until  r> @ ;

: SPI1-OUT      ( b -- )        spi1-i/o drop ;
: SPI1-IN       ( -- b )        0 spi1-i/o ;

v: fresh

dm 1000 spi0-on  1 0 loopback
\ 44 spi0-i/o . many
\ : T1  -1 begin  1+  dup spi0-i/o drop  key? until  drop ;

\ End
