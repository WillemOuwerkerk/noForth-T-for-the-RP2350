\  Build UF2 binary file for RP2040 & RP2350 with RAM bootloader
\
\   Based on the original code from Willem Jager but simplyfied, W.O. 01jun2025
\   Now converted to a seprate Intel-Hex to UF2-file converter.
\
\


\ Build a toolset for UF2 generator
hex
create BIN-BUFFER       320000 allot \ 3000 kByte binary buffer
create UF2-BUFFER       400000 allot \ 6000 kByte Intel-Hex & UF2 file buffer

0 value #ORG      \ HEX origin
0 value #ADDR     \ Current address
0 value CHK
0 value #LINE
: ><        ( a -- b )  dup  FF and 8 lshift  swap 8 rshift FF and  or ;
: XKEY      ( -- c )    #org c@  1 +to #org  ( dup emit ) ;

: NUM>      ( -- n )    xkey upc 10 digit 0= abort" No number!" ; \ Convert char to number

: IHX>      ( -- b )    num> 10 *  num> or  dup +to chk ; \ Hex byte to number
: CHK?      ( -- )      chk negate ff and ihx> <> abort" Checksum" ; \ Checksum control
: ADDR>     ( -- a )    ihx> 10 lshift  ihx> ><  ihx> or or ;        \ Hex word to address
: BC!       ( b -- )    #addr c! ;
: BC,       ( b -- )    bc!  1 +to #addr ;

: SKIPCOLON ( -- )      \ Wait for : char
    20 0 do  xkey [char] : = if unloop exit then  loop  true abort" Structure?" ;

forth definitions
0 value AA
: HEX>BIN   ( -- )
    bin-buffer to #addr  0 to #line \ Initialise address & record length
    begin
        skipcolon               \ Wait for new ihx-line
        0 to chk                \ Start new checksum
    ihx> ?dup while             \ Get Intel HEX record length, not zero?
        addr> to AA 1 +to #line \ skip address
        ihx> 0<> abort" Invalid rec." \ Check if record type is valid
        0 ?do  ihx> bc,  loop   \ Read & store one line
        chk?                    \ Check checksum?
    repeat  cr ." Intel-Hex to binary done " ;


\ string operations, no overflow testing!
\ a2 = counted string address
: PLACE ( a n a2 -- )   \ store a,n as counted string at a2
    2dup c! 1+ swap move ;
: +TEXT ( a n a2 -- )   \ append text
    >r tuck r@ count + swap move
    r@ c@ +
    r> c! ;
: +CH ( ch a2 -- )      \ append a character
    >r r@ count + c!
    r@ c@ 1+
    r> c! ;

create BIN-FILE 0 c, 30 allot align
create HEX-FILE 0 c, 30 allot align
create UF2-FILE 0 c, 30 allot align

: !HEX-FILE ( a u -- )
    HEX-FILE place                  \ Save basic file name
( ) cr cr hex-file count type       \ Show basic file name
( ) HEX-FILE count UF2-FILE place   \ Copy to UF2 file name
    HEX-FILE count BIN-FILE place   \ Copy binary file name
    [char] - UF2-FILE +ch           \ Add dash
    time&date [ decimal ] 100 mod   \ Add date
    3 0 do
    10 /mod [char] 0 + UF2-FILE +ch [ hex ]
            [char] 0 + UF2-FILE +ch
    loop 2drop drop
    s" .uf2" UF2-FILE +text         \ Add extensions
    s" .hex" HEX-FILE +text
    s" .bin" BIN-FILE +text
    BIN-FILE count lower            \ Use lower case file names
    HEX-FILE count lower
    UF2-FILE count lower ;


\ Step-1 Read Intel-Hex file to buffer
0 value BIN#
: READ-HEX   ( ccc -- )     \ Open secundairy boot and image file, note size!
    bl word count !HEX-FILE \ save file names
    HEX-FILE count r/o bin open-file \ Add secundairy boot file
    abort" File failed " >r
    r@ file-size throw d>s to bin#
    uf2-buffer 400000 r@ read-file throw drop
    r> close-file throw
    cr ." Intel-Hex read to buffer " ;


\ Step-2: Convert Intel-Hex to binary file
: MAKE-BIN  ( -- )  uf2-buffer to #org   hex>bin ;


\ Step-3: Convert binary file to valid UF2-file
10000000    value 'TARGET   \ Pico flash start address
0           value #BLOCKS   \ Total number of UF2 blocks
0           value BIN#      \ Binary size
uf2-buffer  value 'PTR      \ UF2 address pointer
E48BFF56    value FID       \ Family ID for RP2040 by default

: RP2040    ( -- )      E48BFF56 to fid ;
: RP2350    ( -- )      E48BFF59 to fid ; \ was ..ff59/ff57
: RAM       ( -- )      20000000 to 'target ;
: ROM       ( -- )      10000000 to 'target ;

: BC!+      ( b -- )    'ptr c!  'ptr 1+ to 'ptr ;  \ Store byte & advance
: B!+       ( x -- )    'ptr !   'ptr 4 + to 'ptr ; \ Store word & advance
: UF2-HEAD  ( blk# -- ) \ Store UF2 block header
    0A324655  b!+       \ Number 1, a string
    9E5D5157  b!+       \ Number 2
    00002000  b!+       \ Family ID presence
    'target   b!+       \ Destination address
    00000100  b!+       \ Data block size
    ( blk# )  b!+       \ Current block number
    #blocks   b!+       \ Total number of blocks
    fid       b!+ ;     \ Pico family ID

: WRITE-BLOCK ( a1 block# -- a2 )
    uf2-head                    \ UF2 block header & Block addresses
    100 0 do  count bc!+  loop  \ Copy one binary block to UF2
    [ 200 124 - ] literal       \ Pad block with zero's
    0 do  0 bc!+  loop
    0AB16F30 b!+                \ And closing magic number
    'target 100 + to 'target ;  \ Increase destination address

: CALC-BLOCKS ( -- )
    #addr bin-buffer -
    100 /mod swap 0 > 1 and +   \ Calc. & round UF2 blocks
    to #blocks ;                \ Correct & save number of blocks

: BUILD-UF2   ( -- )            \ Build UF2-style binary file
    cr ." Converting binary to UF2 "
    bin-buffer  #blocks 0 ?do
        i write-block           \ Write UF2 block 'i'
    loop  drop  ." done " ;

: MAKE.UF2      ( ccc -- )      \ Make uf2 file from binary image
    10000000 to 'target         \ Initialise UF2 converter
    uf2-buffer to 'ptr
    calc-blocks  build-uf2
    uf2-file count              \ Get UF2 file name
    w/o bin create-file         \ (Re)define UF2 file
    abort" File failed "  >r    \ Succeeded, save FID
    uf2-buffer 'ptr over -      \ Calc. file length to save
    r@ write-file throw         \ Write UF2-file
    r> close-file throw         \ Ready
    cr ." The UF2 file: "  uf2-file count type
    ."  is written " ;


0 value FILEID
: MAKE.BIN          \ Make noforth binary file
    bin-file count
    w/o bin create-file throw
    to fileid
    bin-buffer  #addr
    over - fileid write-file drop
    fileid close-file throw
    cr bin-file count type ."  done " ;

\ Read Intel-Hex to UF2-buffer, convert to binary in BIN-buffer
\ Finally build an UF2-file out of it in the UF2-buffer and
\ write the resulting file to disk
: HEX>UF2   ( ccc -- )
    read-hex  make-bin  make.uf2 cr ;

\ Read Intel-Hex to UF2-buffer, convert to binary in BIN-buffer
\ and write the resulting file to disk
: HEX>BIN   ( ccc -- )
    read-hex  make-bin  make.bin cr ;

\ Read binary file 'ccc' to buffer, set all pointers en generate an UF2
: BIN>UF2   ( ccc -- )
    bl word count 2dup !HEX-FILE \ save file names
    calc-blocks  included  make.uf2 cr ;

RP2350 \ Selecteer target

forth
cr cr .( Intel Hex to UF2 converter loaded )
cr .( Usage: HEX>UF2 "filename" )
cr .( The input filename extension must be .HEX )
cr
cr .( Binary to UF2 converter loaded too )
cr .( Usage: BIN>UF2 "filename" )
cr .( The input filename extension must be .F )
cr .( Choosen target: ) FID E48BFF59 = [if] .( RP2350 ) [else] .( RP2040 ) [then]
cr 

\ <><>
