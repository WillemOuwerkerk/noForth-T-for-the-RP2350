hex  v: inside also  definitions
D0000030    constant GPIO-OE        \ GPIO output enable
D0000010    constant GPIO-OUT       \ GPIO output value

dm 17   bitmask constant STR        \ Bamboe uses three I/O bits
dm 18   bitmask constant OUT
dm 19   bitmask constant CLK

v: extra definitions
: BAMBOE-ON ( -- )
    5A [ 11 ] literal      pads! \ Enable strobe output on pin
    5A [ 11 1+ ] literal   pads! \ Enable data output on pin + 1
    5A [ 11 2 + ] literal  pads! \ Enable clock output on pin + 2
    [ str out clk or or ]
    literal  gpio-oe **bis ;  bamboe-on

: READY     ( -- )      \ Copy serial clocked in bits to the parallel outputs
    str gpio-out **bis 1 us str gpio-out **bic ;

: >BAMBOE   ( b -- )    \ Shift one byte out
    dm 24 lshift                \ Data to high byte
    8 for                       \ 8 bits
        dup 0< if               \ Highest bit set?
            out gpio-out **bis  \ Data high
        else
            out gpio-out **bic  \ data low
        then
        clk gpio-out **bic      \ Clock low
        clk gpio-out **bis      \ Clock high
        2*                      \ Next bit
    next  out gpio-out **bic  drop ;

v: inside definitions
2 constant #B          \ Number of used bamboe's
#B 8 * constant #BITS   \ Total number of I/O bits
v: extra definitions
create BITS  #BITS allot  align \ Bit mirror for bamboe

: >BB       ( -- )      \ Copy mirror to bamboe
    #B for
        bits i + c@ >bamboe
    next  ready ;

v: inside definitions
: LOC       ( +n a1 -- bit a2 ) \ Bit location in byte-address a2
    over 3 rshift +  >r         \ Convert to byte addresses
    07 and bitmask  r> ;        \ Convert low nibble to bit mask

v: extra definitions
: ZERO      ( -- )          bits #B 0 fill ; \ Fill mirror with zeros
: SET       ( +n a -- )     loc *bis ;  \ Set bit +n in the mirror
: CLR       ( +n a -- )     loc *bic ;  \ Clear bit +n in the mirror

v: fresh
shield BAMBOE\


bamboe-on
1 >bamboe 2 >bamboe ready

