(* RP2350 secundary boot:
    noForth variant no need for patches, length: 122 bytes

    Things to check & note:
        Note entry addresses for COLD & COLD2
        Check & note RAM address of the BOOT cell address in CFG
*)

s" boot-nof4" !myname

anew -targ

hex previous  forth also definitions
20000000 to MSTART      \ Start of binary
20000000 to IVECS       \ 42 vectors & default code
200000D0 to IVECS/      \ Temporary gap for .T code
200000D0 to HOT         \ Uhere starts here
\ 200000D0 to FROZEN      \ meta uhere (HOT & FROZEN are the same)
20000000 to ORIGIN      \ HERE starts here
\ ... system ...
2000F800 to FLYBUF      \ 400 bytes
2000FC00 to FLYBUF/
2000FD00 to S0          \ 100 bytes
2001FF00 to R0          \ 200 bytes
2001FF00 to TIB         \ 100 bytes
20020000 to TIB/
20020000 to BORDER      \ Systems end
20080000 to RAMTOP      \ End of user RAM

meta also definitions  forth
8000 constant R0   8001 constant R1   8002 constant R2    8003 constant R3
8004 constant R4

:::NOFORTH:::
notrace

    ramtop ,                    \ Ram address voor stack
    -1 ,                        \ Reset vector
    image-def                   \ Add picobin structure

label-amsterdam     \ R0=lookup code, R1=secure key, R2=rom address
    { lr } push,
    r2 0 # movs,                \ ROM address base
    r1 4 # movs,                \ ARM secure key
    hop  r2 16 #) ldrh,         \ Read address of helper function
    hop blx,                    \ Find to address or 0 when not
    hop r0 movs,                \ Save function address
    { pc } pop,

chere 10000000 -  ivecs cell+ vec!  \ Install BOOT at second location in IVECS
cr chere . cr 

\ Call rp2040 ROM functions to enable XIP (execute code in place)
    r0 char I char F  b+b # movw, \ Connect internal flash
    amsterdam bl,
    hop blx,
    r0 char F char C  b+b # movw, \ Flash flush cache
    amsterdam bl,
    hop blx,
    r0 char C char X  b+b # movw, \ Flash enter cmd xip
    amsterdam bl,
    hop blx,
\ COLD start entry for boot image: 1000001C + 1
    r1 10000100 #w mov32,       \ R1 = Flash image address
    r2 401000B0 #W mov32,       \ R2 = Scratch0
    r3  r2 ) ldr,               \ R3 = Scratch0 @
    r3 0 # cmp,  =? no if,      \ Not zero?
        r1 r3 movs,             \ Replace image address
    then,
    r4  r1 ) ldr,               \ R4 = image length
    r2 r4 movs,                 \ R2 = image length copy
    day 20000000 #w mov32,      \ R0 = RAM destination address
    begin,
        r4 4 # subs,            \ Decrease pointer
        r3  r1 r4 r) ldr,       \ Reading word from ROM
        r3  day r4 r) str,      \ Store word in RAM
    =? until,                   \ Ready when all image is copied
    sun 158 # movw,             \ check boot record offset   ****WO****
    r3  day sun r) ldr,         \ Read boot type word?
    r3 0 # cmp,                 \ Single binary boot?
    =? no if,                   \ No, double binary?
        r1 r2 add,              \ Ok, calc. start of second image in R1
        r4  r1 ) ldr,           \ Read next image length to R4
        r4 0 # cmp,             \ Test length
        neg? no if,             \ Length not negative?
            r0 20040000 #w mov32, \ Ok, set next RAM destination address
            begin,
                r4 4 # subs,      \ Decrease pointer
                r3  r1 r4 r) ldr, \ Reading word from ROM
                r3  r0 r4 r) str, \ Store word in RAM
            =? until,           \ Ready when all image is copied
        then,
   then,
    r1 E000ED08 #w mov32,       \ R1 = reset vector register (VTOR)
    day  r1 ) str,              \ DAY = Set address of VTOR
( ) dsb,                        \ Wait until all data is handled
( ) isb,                        \ Wait until all opcodes are executed
    r1  day 4 #) ldr,           \ R1 = First image WARM start from reset vector
    r1 bx,                      \ Jump to it


chere FF FF fill     \ Unused remainder
chere .

;;;NOFORTH;;;

CHERE  to ROMHERE

make.bin

\ End
