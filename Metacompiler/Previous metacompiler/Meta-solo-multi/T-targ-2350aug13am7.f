\ noForth RP2350 long -- targ = 20276 bytes -- 04jul2026 --

<----
\ noForth T & noForth Tv ( not compact )
\ 02jan2023 Start of target code
\ 03jan2023 Added code to line 700
\ 04jan2023 Compiles to WARM that is unfinshed
\ 05jan2023 Rewrote: TRAP QUIT TIDY
\ 10jan2023 Change memory layout
\ 02feb2023 Corrected U> & INLS
\ 04feb2023 Added IMAGE , FREEZE , IVECS & VEC!
\ 05feb2023 Updated FREEZE & IMMEDIATE
\ 09feb2023 Updated GROW COLD PFX VALUE UVALUE VARIABLE & replace DHERE
\ 10feb2023 Removed BL) now uses this:  46E7B401 , is: { ip } push, pc does mov,
\ 11feb2023 Removed a register error from MOVE, now EVALUATE works fine
\ 18feb2023 Rewritten FREEZE, smaller & more solid
\ 22feb2023 125 MHz startup works, added >BAUD
\ 25feb2023 Flexible startup, added CONFIG S? MHZ, etc.
\ 06mar2023 Renamed, documented and rewritten parts like {W & FREEZE
\ 19mar2023 Corrected incorrect defined UNLOOP
\ 25mar2023 Corrected overwritten DOES register & NOCATCHFRAME exit in THROW
\ 27mar2023 Corrected typo in DIG? thanks to Ulli
\ 28mar2023 Updated to new FHERE factorisation: >FHERE ?FHERE
\ 26apr2023 Added a second noForth system for core-1
\ 28apr2023 Corrected FREEZE for dual system
\ 02may2023 Finished noForth duo version, generates a .BIN
\ 19may2023 Optimised code parts of: WARM , WITHIN , /STRING , updated FREEZE
\ 22may2023 Added overclocking to 250MHz
\ 13jun2023 Moved noForth T duo to banked memory now completely independent
\ 28jun2023 Added PADS! & GPIO! for I/O settings, Added IRQ! for setting
\           IRQ vectors, changed NEXT & use banked memory on all systems now
\ 10jul2023 Added US, optimised TRAP & ?STACK uses literal pool more efficient
\ 21jul2023 Added NONAME and a rewrite of CODE
\ 06aug2023 Added DATA> and CODE> for commacode renamed WARM to BOOT
\ 13aug2023 Added [IF] [ELSE] [THEN] so configuration could be a single file!
\ 31aug2023 Added new (dis)assembler, rewritten all three target files
\ 13sep2023 Changed CONFIG, CFG uses TELL to act as table
\ 26sep2023 Simplyfied CONFIG, updated FREEZE(2)
\ 29nov2023 Added CATCH on APP vector, !S0 & updated NONAME
\ 17apr2024 Secured SHIFTs
\ 18may2024 Rearranged source, removed CRC & -CRC, added CHK, renamed DHERE to DP
\           Removed BASE? >IN? STATE? Renamed: TOT( to TO(T etc.
\ 29may2024 Rearranged CFG, combined UART & GPIO-pin nr. added GPIO address register
\ 28jun2024 Changed REFILL & QUIT and optimised THROW & ?STACK
\ 30jul2024 Added 'REFILL >UART, changed REFILL, QUIT, EMIT) etc. and optimised THROW
\ 31jul2024 Removed extra cells for KEY etc. adjusted source accordingly
\ 04dec2024 Renamed 'REFILL to &REFILL and added WINTERPRET
\ 05may2025 Added .XON, etc. Rewote: QUIT REFILL HX SWALLOW TIDY
\ 29may2025 Redesign of ROUTINE CODE NONAME CODE> ;CODE END-CODE (DATA DATA)
\ 09JUN2025 Rewrote hardfault handler, to use BOOT to return
\ 17jul2025 Rewrote CONFIG SWITCH & EMIT) KEY) KEY?) >UART BAUD SET-UART S?
            Rearranged configuration table, updated example files
\ 24sep2025 Added extension vectors: &CONFIG &FAULT with the same function as &REFILL
\ 10jul2026 Started RP2350 conversion
\ 17aug2026 Ended first version with COLD & COLD2 using SCRATCH0
\ 22aug2026 Refactored PLL> added a separate VCORE word for core voltage

\ The bootcode now is our own, Jeroen Hoekstra did the design of it
\ We only use one PLL to generate all clocks, including USB so the 
\ second PLL is free to use, also we have a word KHZ that allows the 
\ programmer to select any CPU frequency between 10kHz and MAX-CLK in Hz
\ Inspiration came from: Jan Bramkamp & Trevis Bemann work

Additional RAM at 0x50100000 = 4 kbyte USB buffer
---->

anew -targ
hex also forth
vocskey

\ The system is entirely in RAM:
20000000        to MSTART  \ Start of binary
mstart 00000 +  to IVECS   \ 48 vectors & default code
mstart 00110 +  to IVECS/  \ Temporary gap for .T code
mstart 00110 +  to HOT     \ Uhere starts here
20040110        to HOT1    \ Hot for second core!
mstart 00200 +  to ORIGIN  \ HERE starts here
\ ... system ...
\ mstart 3F800 +  to BORDER  \ End of user dictionary
mstart 3F800 +  to FLYBUF  \ 400 bytes
mstart 3FC00 +  to FLYBUF/
mstart 3FE80 +  to R0      \ 280 bytes
mstart 3FF80 +  to S0      \ 100 bytes
mstart 3FF80 +  to TIB     \ 080 bytes
mstart 40000 +  to TIB/
mstart 40000 +  to BORDER  \ Systems end
mstart 80000 +  to RAMTOP  \ End of user RAM for image-0
20080000        to XRAM    \ Ram for background tasks, etc.

:::NOFORTH:::
notrace

\ NOOP = NEXT routine ------ wo 02jan2023
\ NEXT, DOES-intro, Low->High
    tos  sp -) str,     \ 3 - pc does mov, is jump to ORIGIN
    tos w mov,          \ 1 - W contains data address
\ Low->High
    ip hop 4 # adds.mv, \ 1 - IP to start of colon def.
\ NEXT  address = origin + 8
label-amsterdam
    ip  { w } ldm,      \ 2 - Read next word address to W & increase IP
    w  { hop } ldm,     \ 2 - Word's CFA contents to HOP & increase W
    pc hop mov,         \ 2 - Go to real code

extra: header NOOP  amsterdam doer,

forth: code EXECUTE ( xt -- )  \ Perform word 'xt'     \ ok
    w tos mov,          \ 1 - XT=CFA to W
    tos  sp )+ ldr,     \ 2 - Reload TOS
    hop  w )+ ldr,      \ 1 - Address in CFA to HOP
    pc hop mov,         \ 2 - Jump to code
end-code

forth: code EXIT ( -- )
label-amsterdam
    { ip } pop,         \ 3 - Unnest colon definition
    next,               \ 6
end-code
extra: code ?EXIT  ( f -- )    \ Leave colon def. when true
    w tos mov,
    tos  sp )+ ldr,         \ 2 - Replace TOS
    w 0 # cmp,
    amsterdam 77 =? until,  \ 2 - Yes, ready no jump to EXIT
    next,                   \ 6
end-code
extra: code DIVE ( -- ) \ Return stack swap
    day ip mov,         \ 1 - Save current IP
    ip  rp ) ldr,       \ 2 - Load IP from R-stack
    day  rp ) str,      \ 2 - Store DAY at R-stack
    next,               \ 6
end-code


<----
\ Primitive completely independent tracer
code .DO  ( -- ) hop does mov,     ahead, >box  end-code
code .IP  ( -- ) hop ip mov,       ahead, >box  end-code
code .RP@ ( -- ) hop  rp 0 #) ldr, ahead, >box  end-code
code .RP  ( -- ) hop rp mov,       ahead, >box  end-code
code .SP  ( -- ) hop sp mov,       ahead, >box  end-code
code .4TH ( -- ) hop  sp 8 #) ldr, ahead, >box  end-code
code .3TH ( -- ) hop  sp 4 #) ldr, ahead, >box  end-code
code .2TH ( -- ) hop  sp ) ldr,    ahead, >box  end-code
code .TOS ( -- ) hop tos mov,
box> then,  box> then,  box> then,  box> then,
box> then,  box> then,  box> then,  box> then,


\ ..... build string in RAM gap =
    moon  pc ) ldr, origin 4 - ## \ MOON = In free user RAM
    sun 0 # movs,               \ counter=0
    day 20 # movs,              \ bl
    day  moon ) strb,           \ a space at the end
    begin,
        day hop mov,            \ Data from HOP to DAY
        w 0F # movs,            \ W = 0F
        day w ands,             \ Mask low nibble of DAY
        day 9 # cmp,            \ DAY > 9
        u>? if,  day 7 # adds,  \ for A B C D E F
        then,  day 30 # adds,   \ Add char 0
        day  moon -) strb,      \ Add to string
        sun 1 # adds,           \ counter 1+
        hop 4 # lsrs,           \ next nibble
    =? until,                   \ string: MOON=address, SUN=length
\ ..... print the string
    sun 1 # adds,               \ to print space too
label-amsterdam
    day  pc ) ldr,  40070000 ## \ UART0 base address
    begin,
        begin,                  \ emit? wait loop
            hop  day 18 #) ldr, \ Read status register
            w 20 # movs,
            hop w ands,         \ Isolate TXE
        =? until,
        w  moon )+ ldrb,        \ next character
        w  day ) strb,          \ emit
        sun 1 # subs,           \ counter 1-
    =? until,
    next,
end-code

code NL ( -- )      \ New line
    moon  pc ) ldr,  origin 10 - ## \ MOON = CR start
    day  0D # movs,
    day  moon )+ strb,
    day  0A # movs,
    day  moon )+ strb,
    moon 2 # subs,
    sun 2 # movs,
    amsterdam bl,
    next,
end-code
---->

\ wo 02jan2023 defining words
forth: code CREATE   ( -- a )  tos  sp -) str, tos w mov, next,  end-code
forth: code :        ( -- )    { ip } push, ip w mov, next,  end-code
forth: code :NONAME  ( -- )    { ip } push, ip w mov, next,  end-code
forth: code CONSTANT ( -- x )  tos  sp -) str, tos  w ) ldr, next,  end-code
forth: code VARIABLE ( -- a )  tos  sp -) str, tos w mov, next,  end-code
forth: code VALUE    ( -- x )  tos  sp -) str,  tos  w ) ldr,  next, end-code

inside: code TVAR    ( -- a )
    tos sp -) str, tos w ) ldr,  tos TP add, next,  end-code
inside: code TVAL    ( -- x )
    tos sp -) str,  tos w ) ldr,  tos TP add,  tos tos ) ldr, next,  end-code

extra: code UVALUE   ( -- x )
    tos  sp -) str,  tos  w ) ldr,  tos  tos ) ldr,  next, end-code
extra: code UVARIABLE ( -- a )
    tos  sp -) str,  tos  w ) ldr,  next,  end-code

\ wo 02jan2023 compiler words
forth: create LITERAL immediate  NONAME
    tos sp -) str,      \ 3 - Save TOS
    ip  { tos } ldm,    \ 2 - Read & skip literal
    next,               \ 6
end-code
forth: create 2LITERAL immediate NONAME
    sp 8 # subs,        \ 1 - Reserve space on sp
    tos  sp 4 #) str,   \ 2 - Save TOS
    ip  { tos day } ldm, \ 2 - Read 2lit TOS = High, DAY = Low
    day  sp ) str,      \ 2 - Save DAY
    next,               \ 6
end-code
forth: create ; immediate   ' exit @ doer,

extra: create ME myname,
extra: create ME2 myname2,

forth: create AHEAD immediate NONAME  ( -- ) \ Jump to inline address
label-amsterdam         \ r(((
    ip  { ip } ldm,     \ 2 - IP @ @ & to IP
    next,               \ 6
end-code  immediate
forth: create IF immediate NONAME
    tos 0 # cmp,                \ 1 - TOS zero?
    tos  sp )+ ldr,             \ 2 - Replace TOS
    amsterdam 77 =? no until,   \ 2 - Jump when zero
    ip 4 # adds,                \ 1 - Otherwise skip jump address
    next,                       \ 6
end-code
forth: create UNTIL immediate NONAME
    tos 0 # cmp,                \ 1 - TOS zero?
    tos  sp )+ ldr,             \ 2 - Replace TOS
    amsterdam 77 =? no until,   \ 2 - Jump when zero
    ip 4 # adds,                \ 1 - Otherwise skip jump address
    next,                       \ 6
end-code
forth: create AGAIN immediate AMSTERDAM doer,       \ r)))

\ ----- for-next -----
\
\                /<<<<<<<<<<<<<<<
\ u FOR offset1 ..code.. NEXT offset2 ..klaar..
\           >>>>>>>>>>>>>>>>>>>>>>>>>/
\ de offsets zijn 32bits absoluut
\ offset1 wijst naar ..klaar..
\ offset2 wijst naar ..code..
\
extra: create FOR  ( -- ) immediate NONAME
    tos nzr? if,                \ 1 - TOS not zero
        tos 1 # subs,           \ 1 - Adjust loop index
        { tos } push,           \ 3 - Push on R-stack
        tos  sp )+ ldr,         \ 2 - Restore TOS
        ip 4 # adds,            \ 1 - Skip jump
        next,                   \ 6
    then,
    tos  sp )+ ldr,             \ 2 - Restore TOS
    ip  { ip } ldm,             \ 2 - Make jump
    next,                       \ 6
end-code
extra: create NEXT  ( -- ) immediate NONAME
    day  rp ) ldr,              \ 2 - Get loop index from RP to DAY
    day nzr? if,                \ 1 - DAY not zero?
        day 1 # subs,           \ 1 - Decrease index
        day  rp ) str,          \ 2 - Save on RP
        ip  { ip } ldm,         \ 2 - Make jump
        next,                   \ 6
    then,
    rp 4 # add,                 \ 1 - Zero, pop index
    ip 4 # adds,                \ 1 - Skip jump
    next,                       \ 6
end-code

\ do-loop & co
\
\           >>>>>>>>>>>>>>>>>\
\ x y DO pointer ..code.. LOOP ..klaar..
\ de absolute 32bits offset wijst naar ..klaar..
\
forth: create DO    immediate  NONAME  \ 23 cycles, 26 bytes
    day sp )+ ldr,          \ 2 - Limit
label-amsterdam
    hop tos movs,           \ 1 - HOP = index
    day tos day subs.mv,    \ 1 - Index - Limit
    w 1 # movs,             \ 1 - Make sign
    w 1F # lsls,            \ 1 -
    day w adds,             \ 1 - Calc. signed limit
    sun ip 4 # adds.mv,     \ 1 - SUN = loop address
    { hop day sun } push,   \ 4 - First address, then calced limit, then index
    tos sp )+ ldr,          \ 3 - Pop TOS
    ip 4 # adds,            \ 1 - Skip jump
    next,                   \ 6
end-code

forth: create ?DO  ( -- )  immediate  NONAME \ 8 cycles, 16 bytes
    day  sp )+ ldr,         \ 2 - Pop limit
    day tos cmp,            \ 1 - Test limit against index
    amsterdam 77  =? until, \ 2 - Ready when equal
    tos  sp )+ ldr,         \ 2 - DROP, replace TOS
    ip  { ip } ldm,         \ 2 - Make jump to ..ready..
    next,
end-code

forth: code LEAVE ( -- )        \ 12 cycles, 14 bytes
    ip  rp 8 #) ldr,        \ 2 - Read loop address
    ip 4 # subs,            \ 1 - Go one cell back
    ip  { ip } ldm,         \ 2 - Read there the unloop address
label-amsterdam
    rp 0C # add,            \ 1 - Remove all loop data
    next,                   \ 6
end-code
forth: header UNLOOP  AMSTERDAM doer,

forth: create LOOP  ( -- )  immediate   NONAME \ 20 cycles, 22 bytes
    day rp ) ldr,           \ 2 - Increase index with 1
    day 1 # adds,           \ 1
    sun rp 4 #) ldr,        \ 2 - Increase adjusted limit with 1
    sun 1 # adds,           \ 1
    amsterdam 77 vs? no until, \ 1/2 - Ready when overflowed
    day rp ) str,           \ 2 - Save index
    sun rp 4 #) str,        \ 2 - Save limit
    ip  rp 8 #) ldr,        \ 2 - Jump back when no overflow
    next,                   \ 6
end-code

forth: create +LOOP  ( step -- )  immediate   NONAME \ 23 cycles, 26 bytes
    sun tos movs,           \ 1 - Read & pop step
    tos  sp )+ ldr,         \ 2
    day rp ) ldr,           \ 2 - Increase index in DAY with step
    day sun adds,           \ 1
    day rp ) str,           \ 2
    moon rp 4 #) ldr,       \ 2 - Increase adjusted limit with step
    moon sun adds,          \ 1
    moon rp 4 #) str,       \ 2
    amsterdam 77 vs? no until, \ 1/2 - Ready when overflowed
    ip  rp 8 #) ldr,        \ 2 - Jump back when no overflow
    next,                   \ 6
end-code

forth: code I      ( -- i )
    tos  sp -) str,  tos  rp ) ldr,  next,
end-code
\ forth: code J      ( -- j )
\    tos  sp -) str,  tos  rp 0C #) ldr,  next,
\ end-code

\ <><>

\ wo 06jan2023, design Albert Nijhof, DU*S   UM*   *   UM/MOD   DU/S
\
forth: code UM*    ( u1 u2 -- ud )
    hop  sp ) ldr,
    hop tos hop tos umull,
    hop  sp ) str,
    next,
end-code

forth: code *      ( a b -- c )
    day  sp )+ ldr,     \ 2 - Pop integer A
    tos day mul,        \ 1 - Multiply A * B
    next,               \ 6
end-code

\ wo 06jan2023 ----- divide ----- UM/MOD  DU/S
\ r0 = ip,  r1 = sp,  r2 = w,  r3 = tos,  r4 = hop,  r5 = day,  r6 = sun,  r7 = moon
label-amsterdam         \ UM/MOD & DU/S subroutine    \ ok
    tos sun cmp,        \ TOS = u, SUN = hi,  MOON = lo -> SUN = Rest, MOON = Quot
    u>? no if,          \ Overflow?
        sun 0 # movs,   \ SUN = MOON = -1
        sun sun mvns,
        moon sun mov,
        lr bx,
    then,
label-rotterdam
    day 1 # movs,       \ Init. counter
    begin,
        moon moon adds,  sun sun adcs,
        cs? no if,
            tos sun cmp,
            u>? no if,    2SWAP
        then,
                sun tos subs,
                moon 1 # adds,
            then,
        day day adds,
    cs? until,          \ Bit comes out?
    lr bx,

forth: code UM/MOD ( du u -- rest quot )   \ ok
    sun  sp )+ ldr,     \ SUN = Hi
    moon  sp ) ldr,     \ MOON = Lo
    amsterdam bl,
    sun  sp ) str,      \ Rest
    tos moon mov,       \ Quot
    next,
end-code
extra: code DU/S   ( u64 u16 -- uu64 u16 ) \ ok
    sun 0 # movs,       \ SUN = 0, MOON = hi
    moon  sp ) ldr,
    rotterdam bl,
    moon  sp ) str,     \ qhi
    moon  sp 4 #) ldr,  \ SUN = rest, MOON = lo
    rotterdam bl,
    moon  sp 4 #) str,  \ qlo
    tos sun mov,        \ rest
    next,
end-code

extra: 4        constant CELL
forth: 20       constant BL
extra: hot      constant HOT
extra: origin   constant ORIGIN
extra: ivecs    constant IVECS
extra: 00000    constant FROZEN
extra: 81000    constant FROZEN2
inside: XRAM    constant XORG

\ --- system data ---
\ 'warm-start' data in ram          \ Cell 0 to cell 7
( ) dict-threads cells UALLOT

inside: 0   uvalue  PFX-LINK        \ 08 prefix-list, the 1st val after the threads
{{+ inside: 0   uvalue  WID-LINK }} \ 09 wid-list
{{- extra:  0   uvalue VER }}       \ 09 See CR
extra: -1       uvalue 'EMIT        \ 10
extra: -1       uvalue 'KEY?        \ 11
extra: -1       uvalue 'KEY         \ 12
extra: ' NOOP   uvalue APP          \ 13

extra: uhere constant CFG   decimal  uhere
label-cfg
24 25 b+b  15000  h+h  over ! cell+ \ 14 GPIO24 for S?, GPIO25 for led & clk in 10kHz
hex 40070000           over ! cell+ \ 15 Select UART base address
decimal 115200         over ! cell+ \ 16 Baudrate
hex D0000004           over ! cell+ \ 17 GPIO input address register
cr cr dup . cr
decimal  0             over ! cell+ \ 18 Boot type (0=single, 1=two cores)
drop                                \ -1 = Complete system reboot is done
hex  5 cells uallot
inside: ' noop uvalue &CONFIG       \ 19 Vector for alternative configurations
inside: -1 uvalue DP                \ 20 Normal (dictionary) here pointer
inside: -1 uvalue UHERE             \ 21 uhere in RAM

label-tp    \ Start TCB for main task
inside: uhere constant MAIN         \ cell 25 to 35
inside: tp> tvariable TLINK         \ 0 00
inside:  -1 tvariable TSTATE        \ 1 04
inside:   0 tvalue ERR?             \ 2 08 val
inside:  R0 tvariable TRP           \ 3 0C
forth:   10 tvariable BASE          \ 4 10 var
inside: flybuf tvalue FP            \ 6 14 val
extra:  flybuf tvalue FLYBUF        \ 6 18 val
inside: flybuf/ tvalue FLYBUF/      \ 7 1C val
extra:   R0 tvalue R0               \ 8 20 val
extra:   S0 tvalue S0               \ 9 24 val
inside: uhere tp> - constant #TCB   \ TCB size

\ End of dictionary RAM structure
extra: tib uvalue TIB       \ 25 Terminal Input Buffer
extra: tib/ uvalue TIB/     \ 26 tib-end
extra: 07 uvalue OK         \ 27 See .OK
forth: uvariable STATE      \ 29 STATE
forth: uvariable >IN        \ 30 >IN
extra: 0 uvalue #IB         \ 31 inputbuffer len
extra: 0 uvalue IB          \ 32 formal inputbuffer adr

{{+ inside: 0 uvalue VP     \ 33 pointer to search-stack
    8 uallot                \ 34, 36 space for search-stack
inside: uvariable V0 }}     \ 37 contains current voc.

extra:  0 uvalue CREATED    \ 38 LFA of last created header in dictionary.
inside: 0 uvalue CP         \ 39 : {FLY adr fp to cp ; : FLY} adr ROMP to cp ;
inside: 0 uvalue HLD        \ 41 See HOLD <# #>
extra:  0 uvalue HOR        \ 42 See EMIT
{{+ extra: 0 uvalue VER }}  \ 43 Checksum on core
forth:  0 uvalue SOURCE-ID  \ 44 see KEY EVALUATE
extra: xram uvalue XHERE    \ 46 A 1024 bytes memory block start address
label-refill-vec
inside: ' noop uvalue &REFILL \ 47 Alternative REFILL token
inside: ' noop uvalue &FAULT  \ 48 Hardfault handler
extra: -1 uvalue ECHO         \ 49 Echo characters back in ACCEPT
extra: flybuf uvalue BORDER   \ 50 Border pointer (uspace=2xx/2xx bytes)

cr cr uhere u. cr cr        \ HOT + 55??

\ Bottom R-stack
\ R-stack use:  xt
\               tos
\               sp
\               ip
extra: code PAUSE      ( -- ) \ 26 machine cycles, is 0.173 microsec. at 150 MHz
    { ip sp tos } push,     \ 3 - Save Forth environment
    sun TP mov,             \ 1 - TCB address to SUN
    day rp mov,             \ 1 - RP to DAY
    day  sun 0C #) str,     \ 2 - DAY to RP
  begin, >box
    begin,                  \ An inactive task takes 6 cycles extra = 0.040 µs
        sun  sun ) ldr,     \ 2 - Fetch next link to SUN
        day  sun 4 #) ldr,  \ 1 - Next TSTATE @ to DAY
        day 0 # cmp,        \ 1 -
    =? no until,            \ 2 - Not zero?
    TP sun mov,             \ 1 - Next link address = new TCB
    day  sun 0C #) ldr,     \ 2 - RP @ to DAY
    rp day mov,             \ 1 - DAY to RP
    { ip sp tos } pop,      \ 3 - Restore Forth environment
  begin, >box
    next,                   \ 6
end-code

extra: code STOP   ( -- )
    tp> ,  code>
    w  w ) ldr,             \ 2 - MAIN to W
    sun TP mov,             \ 1 - Task to SUN
    sun w cmp,              \ 1 - main = task?
  box> =? no until,         \ 2 - No = continue, yes = ready
    day 0 # movs,           \ 1 - False flag
    day  sun 4 #) str,      \ 2 - Store in TSTATE of myself
    { ip sp tos } push,     \ 4 - Save this tasks Forth environment
    w rp mov,               \ 1 - RP to W
    w  sun 0C #) str,       \ 2 - W to RP
  box> again,               \ 2 - Switch to next task
end-code

extra: code SLEEP  ( task -- )
    tp> ,  code>
    w  w ) ldr,             \ 2 - main to W
    tos w cmp,              \ 1 - main = task?
  =? no if, >box            \ 2 - No = continue, yes = ready
    day 0 # movs,           \ 1
  ahead, >box               \ 10 + 2
end-code

extra: code WAKE   ( task -- )
    day 0 # movs,           \ 1 - Build true flag
    day day mvns,           \ 1
  box> then,                \     Resolve jump
    day  tos 4 #) str,      \ 2 - Store in TSTATE of task
  box> then,
    tos sp )+ ldr,          \ 2 - Drop task
    next,                   \ 6
end-code

(* inside: code >TASK ( ip xt task -- )
    sp  { hop sun } ldm,    \ XT to HOP, IP to SUN
    { ip sp } push,         \ Save noForth registers
    moon rp mov,            \ Save RP
    ip sun mov,             \ Ip to IP
    day tos 20 #) ldr,      \ Read R0 to DAY
    rp day mov,             \ Use R0 as tasks RP
    sp tos 24 #) ldr,       \ Set SP to S0
    { ip sp tos hop } push, \ Initialise tasks return stack
    day rp mov,             \ Copy RP to DAY
    day  tos 0C #) str,     \ Set tasks RP too
    rp moon mov,            \ Restore noForth registers
    { ip sp } pop,
    tos  sp )+ ldr,         \ Pop stack
    next,
end-code
*)


\ Simple tracer usage: .T [char] x emit
\ uvariable T?


\ --- end of warm start data
uhere  ramadr: uhere  !

extra: ramtop constant RAMBORDER \ End of available memory

\ UART0 = 40070000, UART1 = 40078000
\ KEY?)  KEY)  EMIT)
extra: code KEY?)  ( -- f )
    cfg> cell+ ,            \ HOP = CONFIG cell with UART address
code>
    w { hop } ldm,          \ 2 Read config address
    sun  hop ) ldr,         \ 2 UART base is there
    tos  sp -) str,         \ 3
    tos  sun 18 #) ldr,     \ 2 Read flags
    tos 1B # lsls,          \ 1 Build flag out of bit-4
    tos 1F # asrs,          \ 1
    tos tos mvns,           \ 1
    next,
end-code

extra: code KEY)    ( -- c )
    cfg> cell+ ,            \ HOP = CONFIG cell with UART address
code>
    w { hop } ldm,          \ 2 Read config address
    tos  sp -) str,         \ 3
    begin,
        sun  hop ) ldr,     \ 2 SUN = UART base address
        day  sun 18 #) ldr, \ 2 Read flags (UARTFR)
        w 10 # movs,        \ 1 Isolate KEY? flag
        day w ands,         \ 1
    =? until,               \ 1/2 Flag set?
    tos  sun ) ldrb,        \ 2 Read character
    next,
end-code

extra: code EMIT)   ( c -- )
    cfg> cell+ ,            \ HOP = CONFIG cell with UART address
code>
    w { hop } ldm,          \ Read config address
    begin,
        sun  hop ) ldr,     \ SUN = UART address
        day  sun 18 #) ldr, \ Read flags (UARTFR)
        moon 20 # movs,     \ Isolate EMIT? flag
        day moon ands,
    =? until,               \ Flag set?
    tos  sun ) strb,        \ Output character
    tos  sp )+ ldr,
    next,
end-code


\ for values -- tos = x, ip) = inline ramadres van value
inside: code TO(    ( x -- )    \ Store X to inline address
    ip  { day } ldm,    \ 2 - Load address & skip address
    tos  day ) str,     \ 2 - Store TOS in address in DAY
    tos  sp )+ ldr,     \ 2 - Restore TOS
    next,               \ 6
end-code
inside: code +TO(   ( x -- )    \ Store X to inline address
    ip  { day } ldm,    \ 2 - Load address & skip address
    sun  day ) ldr,     \ 1 - Read value
    sun tos adds,       \ 2 - Add x to it
    sun  day ) str,     \ 1 - Store SUN in address in DAY
    tos  sp )+ ldr,     \ 1 - Restore TOS
    next,               \ 6
end-code
inside: code INCR(  ( -- )      \ Store X to inline address
    ip  { day } ldm,    \ 2 - Load address & skip address
    sun  day ) ldr,     \ 2 - Read value to SUN
    sun 1 # adds,       \ 1 - Add 1 to SUN
    sun  day ) str,     \ 2 - Store SUN in address in DAY
    next,               \ 6
end-code
inside: header ADR(  ' literal 2 cells + doer,

inside: code TO(T    ( x -- )    \ Store X to inline address
    ip  { day } ldm,    \ 2 - Load address & skip offset
    day TP add,
    tos  day ) str,     \ 2 - Store TOS in address in DAY
    tos  sp )+ ldr,     \ 2 - Restore TOS
    next,               \ 6
end-code
inside: code ADR(T   ( -- )      \ Store X to inline offset
    tos  sp -) str,     \ 3 - Save TOS
    ip  { tos } ldm,    \ 2 - Load address & skip address
    tos TP add,
    next,               \ 6
end-code
inside: code HIS(T   ( task -- addr ) \ Store X to inline offset
    ip  { day } ldm,    \ 2 - Load offset & skip address
    tos day adds,       \ 1 - Make tasks variable address
    next,               \ 6
end-code

to#   pfx-for-value to(         \ 0
+to#  pfx-for-value +to(        \ 1
incr# pfx-for-value incr(       \ 2
adr#  pfx-for-value adr(        \ 3

create TO.U   ' to(   >body ,   immediate
create +TO.U  ' +to(  >body ,   immediate
create INCR.U ' incr( >body ,   immediate
create ADR.U  ' adr(  @ ,       immediate

create TO.T   ' TO(T   >body ,  immediate
create ADR.T  ' ADR(T  >body ,  immediate
create HIS.T  ' HIS(T  >body ,  immediate

\ in pfx-list hangen
to#   pfx-for-uvalue to.u         \ 0
+to#  pfx-for-uvalue +to.u        \ 1
incr# pfx-for-uvalue incr.u       \ 2
adr#  pfx-for-uvalue adr.u        \ 3

\ in pfx-list hangen
to#   pfx-for-tvalue to.t       \ 0
adr#  pfx-for-tvalue adr.t      \ 3
his#  pfx-for-tvalue his.t      \ 4

\ in pfx-list hangen
his#  pfx-for-tvar his.t        \ 4

\ wo 03jan2023 Return stack tools: !R0   RP@   !S0
inside: code !R0   ( -- )
    day TP mov,
    day  day his: r0 #) ldr,
    rp day mov,
    next,               \ 6
end-code
extra: code RP@    ( -- a )
    tos  sp -) str,     \ 3 - Save TOS
    tos rp mov,         \ 1 - RP to TOS
    next,               \ 6
end-code
inside: code !S0   ( -- )
    day TP mov,
    sp  day his: s0 #) ldr,
    next,               \ 6
end-code

\ wo 03jan2023 Data stack: C!  H!  !  +!  C@  C@+  COUNT
\       @   @+  H@  H@+  COMPILE@  COMPILE!
forth: code C!     ( b a -- )
    day sp )+ ldr,      \ 2 - Pop b to DAY
    day  tos ) strb,    \ 2 - Store DAY to a
    tos  sp )+ ldr,     \ 2 - Replace TOS
    next,               \ 6
end-code
extra: code H!      ( hx a -- )
    day sp )+ ldr,      \ 2 - Pop 'hx' to DAY
    day  tos ) strh,    \ 2 - Store DAY to address in TOS
    tos  sp )+ ldr,     \ 2 - Replace TOS
    next,               \ 6
end-code
forth: code !      ( x a -- )
label-amsterdam
    day  sp )+ ldr,     \ 2 - Pop 'x' to DAY
    day  tos ) str,     \ 2 - Store DAY to address in TOS
    tos sp )+ ldr,      \ 2 - Replace TOS
    next,               \ 6
end-code
inside: header COMPILE! ( x a -- )
    amsterdam doer,

forth: code +!     ( x a -- )
    day  sp )+ ldr,     \ 2 - Pop 'x' to DAY
    sun  tos ) ldr,     \ 2 - Read contents of a
    day sun adds,       \ 1 - Add a contents to DAY
    day  tos ) str,     \ 2 - Store DAY to address in TOS
    tos  sp )+ ldr,     \ 2 - Replace TOS
    next,               \ 6
end-code

forth: code C@     ( a -- b )
    tos  tos ) ldrb,    \ 2 - Load byte b from address a
    next,               \ 6
end-code
extra: code H@      ( a -- hx )
    tos  tos ) ldrh,    \ 2 - Leave 'hx', which is the contents of 'a'
    next,               \ 6
end-code
forth: code @      ( a -- x )
label-amsterdam
    tos  tos ) ldr,     \ 2 - Leave 'x', which is the contents of 'a'
    next,               \ 6
end-code
inside: header COMPILE@ ( a -- x )  amsterdam doer, \ read compiled pointer
inside: header LNK@     ( a -- x )  amsterdam doer, \ read compiled link

extra: code C@+    ( a1 -- a2 b )
label-amsterdam
    day tos mov,        \ 1 - Copy address 'a1'
    tos  day )+ ldrb,   \ 3 - Fetch byte to TOS
    day  sp -) str,     \ 3 - Make room & push address 'a2'
    next,               \ 6
end-code
forth: header COUNT  ( a1 -- a2 b )  amsterdam doer,

extra: code H@+     ( a1 -- a2 x )
    day tos mov,        \ 1 - Copy address 'a1'
    tos  day )+ ldrh,   \ 3 - Fetch half word to TOS
    day  sp -) str,     \ 3 - Make room & push address 'a2'
    next,               \ 6
end-code
extra: code @+     ( a1 -- a2 x )
    day tos mov,        \ 1 - Copy address 'a1'
    tos  day )+ ldr,    \ 3 - Fetch word to TOS
    day  sp -) str,     \ 3 - Make room & push address 'a2'
    next,               \ 6
end-code

\ wo 03jan2023 More returnstack:
\    >R   R>   2>R   2R>   R@   I   2R@   RDROP
forth: code >R     ( x -- )    \ TOS to top RP
    { tos } push,       \ 3 - Push TOS
    tos  sp )+ ldr,     \ 2 - Pop data stack to TOS
    next,               \ 6
end-code
forth: code R>     ( -- x )
    tos  sp -) str,     \ 3 - Save TOS
    { tos } pop,        \ 3 - Pop top RP to TOS
    next,               \ 6
end-code
forth: code 2>R    ( a b -- )
    hop  sp )+ ldr,     \ 2 - HOP = a
    { tos hop } push,   \ 4 - R-stack = a b
    tos  sp )+ ldr,     \ 2 - DROP
    next,               \ 6
end-code
forth: code 2R>    ( -- a b )
    sp 8 # subs,        \ 1
    tos  sp 4 #) str,   \ 2 - Save TOS
    { tos hop } pop,    \ 4 - Read b & a
    hop  sp ) str,      \ 2 - Push HOP = a
    next,
end-code
forth: header R@     ( -- i )   ' I >body doer,

forth: code 2R@    ( -- a b )
    sp 8 # subs,        \ 1 - Reserve stack space
    tos  sp 4 #) str,   \ 2 - Save TOS at lowest position
    tos  rp ) ldr,      \ 2 - Copy R-stack TOP to TOS
    hop  rp 4 #) ldr,   \ 2 - Copy R-stack sec. to HOP
    hop  sp ) str,      \ 2 - Save HOP
    next,
end-code
extra: code RDROP  ( -- )
    { day } pop,        \ 3 - Pop top RP to DAY
    next,               \ 6
end-code


\ wo 03jan2023 More DOUBLE stack operators:
\    2DROP   2DUP   2NIP   2OVER   2SWAP
forth: code 2DROP  ( da -- )
    tos  sp 4 #) ldr,   \ 2 - Replace TOS
    sp 8 # adds,        \ 1 - Remove 2 cells
    next,               \ 6
end-code
forth: code 2DUP   ( da -- da da ) \ 8 4 0
    day  sp ) ldr,      \ 2 - Copy lb
    sp 8 # subs,        \ 1 - Reserve stack space
    tos  sp 4 #) str,   \ 2 - Copy hb
    day  sp ) str,      \ 2 - Copy lb
    next,               \ 6
end-code
extra: code 2NIP   ( da db -- db )
    day  sp ) ldr,      \ 2 - Copy lbb
    sp 8 # adds,        \ 1 - Pop da
    day  sp ) str,      \ 2 - Save lbb
    next,               \ 6
end-code
forth: code 2OVER  ( da db -- da db da )
    tos sp -) str,      \ 3 - Save TOS
    day  sp C #) ldr,   \ 2 - Copy alb to DAY
    tos  sp 8 #) ldr,   \ 2 - Copy alh to TOS
    day  sp -) str,     \ 3 - Save alb
    next,               \ 6
end-code
forth: code 2SWAP  ( da db -- db da )
    day  sp 8 #) ldr,   \ 2 - Read alb
    sun  sp 4 #) ldr,   \ 2 - Read ahb
    moon  sp ) ldr,     \ 2 - Read blb
    moon  sp 8 #) str,  \ 2 - Store blb
    tos  sp 4 #) str,   \ 2 - Store bhb
    day  sp ) str,      \ 2 - Store alb
    tos sun mov,        \ 1 - Copy SUN to TOS
    next,               \ 6
end-code


\ wo 03jan2023 More stack operators:
\   DUP   ?DUP   DROP   OVER
\   SWAP  TUCK   NIP    PICK   ROT
forth: code DUP    ( a -- a a )
label-amsterdam
    tos  sp -) str,     \ 2 - Push TOS to stack
    next,               \ 6
end-code
forth: code ?DUP   ( a -- 0| a a )
    tos 0 # cmp,        \ 1
    amsterdam 77  =? until, \ 2
    next,               \ 6
end-code
forth: code DROP   ( a -- )
    tos  sp )+ ldr,     \ 2 - Pop second stack item to TOS
    next,               \ 6
end-code
forth: code OVER   ( a b -- a b a )
    tos  sp -) str,     \ 3 - Push TOS
    tos  sp 4 # ldr,    \ 2 - Second stack iten to TOS
    next,               \ 6
end-code
forth: code SWAP   ( a b -- b a )
    day  sp 0 # ldr,    \ 2 - Second stack iten to DAY
    tos  sp 0 # str,    \ 2 - TOS to seond stack item
    tos day movs,       \ 1 - DAY to TOS
    next,               \ 6
end-code
forth: code TUCK   ( a b -- b a b )
    sp 4 # subs,        \ 1 - Make extra datastack space
    day  sp 4 #) ldr,   \ 2 - Fetch a to DAY
    day  sp ) str,      \ 2 - Store DAY
    tos  sp 4 #) str,   \ 2 - Store TOS
    next,               \ 6
end-code
forth: code NIP    ( a b -- b )
    sp 4 # adds,        \ 1
    next,               \ 6
end-code
forth: code PICK   ( x1 .. Xn +m -- x1 .. xn xm )
    tos 2 # lsls,       \ 1 - +M times four
    tos  sp tos r) ldr, \ 2 - Indexed read of stack to TOS
    next,               \ 6
end-code
forth: code ROT    ( a b c -- b c a )
    day  sp ) ldr,      \ 2 - b to DAY
    tos  sp ) str,      \ 2 - c to b
    tos  sp 4 #) ldr,   \ 2 - a to TOS
    day  sp 4 #) str,   \ 2 - DAY=b to a
    next,               \ 6
end-code

extra: code B+B    ( lb hb -- x )
    tos  sp 1 #) strb,  \ 2 - Store TOS=hb next to lb
    tos  sp ) ldrh,     \ 2 - Load 16-bits to TOS
    sp 4 # adds,        \ 1 - Drop lb
    next,               \ 6
end-code
extra: code B-B    ( x -- lb hb )
    tos  sp -) str,     \ Push TOS = x
    tos  sp 1 #) ldrb,  \ Read hb to TOS
    day  sp ) ldrb,     \ Read lb to DAY
    day  sp ) str,      \ Write lb back
    next,               \ 6
end-code

extra: code H+H    ( lh hh -- x )
    tos  sp 2 #) strh,  \ 2 - Store TOS=hh next to lh
    tos  sp ) ldr,      \ 2 - Load 32-bits to TOS
    sp 4 # adds,        \ 1 - Drop lh
    next,               \ 6
end-code
extra:  code H-H    ( x -- lh hh )
    tos  sp -) str,     \ Push TOS = x
    tos  sp 2 #) ldrh,  \ Read hh to TOS
    day  sp ) ldrh,     \ Read lh to DAY
    day  sp ) str,      \ Write lh back
    next,               \ 6
end-code


extra: : TKEY?     ( -- f )    key?) dup ?exit  pause ;
extra: : TKEY      ( -- x )    BEGIN  tkey? UNTIL  key) ;
extra: : TEMIT     ( x -- )    emit)  pause ;

' temit    ramadr: 'emit  !
' tkey     ramadr: 'key   !
' tkey?    ramadr: 'key?  !


\ Simple tracer usage: .T [char] x temit
\ extra: : TEMIT ( c -- ) t? @ if dup emit) then drop ;
\ extra: : .T    ( -- )   t? @ if nl .do .ip .rp .sp .4th .3th .2th .tos then ;
\ extra: : TRON  -1 t? ! ;  : TROFF   0 t? ! ;
\ extra: : TEMIT ( c -- ) emit) ;
\ extra: : .T    ( -- ) nl .do .ip .rp .sp .4th .3th .2th .tos ;


\ wo 03jan2023 Comparisions:
\    MIN  MAX  UMIN  UMAX  TRUE  FALSE  0<
\    0=   =    <>    >     U>    <      U<  WITHIN
forth: code MIN    ( a b -- c )
    day  sp )+ ldr,     \ 2 - a to DAY
    tos day cmp,        \ 1 - TOS > DAY
    >? if,              \ 2 - Yes,
label-amsterdam
        tos day mov,    \ 1 - DAY to TOS
    then,  next,        \ 6
end-code
forth: code MAX    ( a b -- c )
    day  sp )+ ldr,     \ 2 - a to DAY
    tos day cmp,        \ 1 - TOS < DAY
    amsterdam 77 <? no until,
    next,
end-code
extra: code UMIN   ( a b -- c )
    day  sp )+ ldr,     \ 2 - a to DAY
    tos day cmp,        \ 1 - TOS u> DAY
    amsterdam 77 u>? no until,
    next,
end-code
extra: code UMAX   ( a b -- c )
    day  sp )+ ldr,     \ 2 - a to DAY
    day tos cmp,        \ 1 - DAY u> TOS
    amsterdam 77 u>? no until,
    next,
end-code

forth: code TRUE   ( -- tf )
    tos  sp -) str,     \ 3 - Save TOS
label-amsterdam
    tos 0 # movs,       \ 1 - TOS = 0
    tos tos mvns,       \ 1 - TOS = -1
    next,               \ 6
end-code
forth: code FALSE  ( -- ff )
    tos  sp -) str,     \ 2
    tos 0 # movs,       \ 1
    next,               \ 6
end-code
forth: code >      ( n1 n2 -- f )
    day  sp )+ ldr,     \ 2 - pop N1 to DAY
    tos day cmp,        \ 1 - Compare DAY & TOS
    amsterdam 77  <? no until, \ 1/10 - TOS smaller or not
    tos 0 # movs,       \ 1 - Not smaller, TOS = 0
    next,               \ 6
end-code
forth: code U>     ( n1 n2 -- f )
    day  sp )+ ldr,     \ 2 - pop N1 to DAY
    day tos cmp,        \ 1 - Compare DAY & TOS
    amsterdam 77  u>? no until, \ 1/10 - TOS smaller or not
    tos 0 # movs,       \ 1 - Not smaller, TOS = 0
    next,               \ 6
end-code
forth: code <      ( n1 n2 -- f )
    day  sp )+ ldr,     \ 2 - pop N1 to DAY
    day tos cmp,        \ 1 - Compare DAY & TOS
    amsterdam 77  <? no until, \ 1/10 - DAY smaller or not
    tos 0 # movs,       \ 1 - Not smaller, TOS = 0
    next,               \ 6
end-code
forth: code U<     ( n1 n2 -- f )
    day  sp )+ ldr,     \ 2 - pop N1 to DAY
    tos day cmp,        \ 1 - Compare DAY & TOS
    amsterdam 77  u>? no until, \ 1/10 - TOS smaller or not
    tos 0 # movs,       \ 1 - Not smaller, TOS = 0
    next,               \ 6
end-code

\ : within ( x a b -- f )      \ x-a u< b-a ?
\    over - >r - r> u< ;
forth: code WITHIN ( x a b -- f )  \ x-a u< b-a ?
    sp { day sun } ldm, \ 3 - DAY=a, SUN=x
    tos day subs,       \ 1 - b-a
    sun day subs,       \ 1 - x-a
    tos sun cmp,        \ 1 - Compare DAY & SUN
    amsterdam 77  u>? no until, \ 1/10 - TOS smaller or not
    tos 0 # movs,       \ 1 - Not smaller, TOS = 0
    next,               \ 6
end-code

forth: code 0<     ( n -- f )
    tos 1F # asrs,      \ 1 - Expand sign to whole cell
    next,
end-code
forth: code =      ( x1 x2 -- f )
    day  sp )+ ldr,     \ 2 - pop X1 to DAY
    tos day subs,       \ 1 - Subtract DAY from TOS
    tos 1 # subs,       \ 1 - When 0 create carry
    tos tos sbcs,       \ 1 - Subtract carry, leaves 0 or -1
    next,               \ 6
end-code
forth: code <>     ( x1 x2 -- f )
    day  sp )+ ldr,     \ 2 - pop X1 to DAY
    tos day subs,       \ 1 - Subtract DAY from TOS
    tos 1 # subs,       \ 1
    tos tos sbcs,       \ 1
    tos tos mvns,       \ 1
    next,               \ 6
end-code
forth: code 0=    ( n -- f )
    tos 1 # subs,       \ 1 - Subtract 1 from TOS
    tos tos sbcs,       \ 1 - Subtract TOS from TOS with carry
    next,               \ 6
end-code
forth: code 0<>   ( n -- f )
    tos 1 # subs,       \ 1 - Subtract 1 from TOS
    tos tos sbcs,       \ 1 - Subtract TOS from TOS with carry
    tos tos mvns,       \ 1 - Invert result
    next,               \ 6
end-code
forth: code S>D    ( n -- d )
    tos  sp -) str,     \ 3 - Save n
    tos 1F # asrs,      \ 1 - Extend sign in TOS
    next,               \ 6
end-code


\ wo 03jan2023 Logical:
\ AND  OR  XOR  INVERT  LSHIFT  RSHIFT  ><  REV
forth: code AND    ( a b -- c )
    day  sp )+ ldr,     \ 2 - pop X1 to DAY
    tos day ands,       \ 1 - AND DAY to TOS
    next,               \ 6
end-code
forth: code OR     ( a b -- c )
    day  sp )+ ldr,     \ 2 - pop X1 to DAY
    tos day orrs,       \ 1 - AND DAY to TOS
    next,               \ 6
end-code
forth: code XOR    ( a b -- c)
    day  sp )+ ldr,     \ 2 - pop X1 to DAY
    tos day eors,       \ 1 - AND DAY to TOS
    next,               \ 6
end-code
forth: code INVERT ( a -- b )
    tos tos mvns,       \ 1
    next,               \ 6
end-code

forth: code LSHIFT ( a b -- c )
    tos 20 # cmp,  u>? if, \ 3 - 20 UMIN
        tos 20 # movs,  \ 1
    then,
    day tos movs,       \ 1 - +n to DAY
    tos  sp )+ ldr,     \ 2 - pop X1 to TOS
    tos day lsls,       \ 1 - Shift TOS DAY positions left
    next,               \ 6
end-code
forth: code RSHIFT ( a b -- c )
    tos 20 # cmp,  u>? if, \ 3 - 20 UMIN
        tos 20 # movs,  \ 1
    then,
    day tos movs,       \ 1 - +n to DAY
    tos  sp )+ ldr,     \ 2 - pop X1 to TOS
    tos day lsrs,       \ 1 - Shift TOS DAY positions left
    next,               \ 6
end-code

extra: code ><     ( a -- b ) \ Byte swap in lower half word
    tos 10 # lsls,      \ 1 - Remove high 16-bits
    tos 10 # lsrs,      \ 1
    tos tos rev16,      \ 1 - Swap bytes
    next,               \ 6
end-code
extra: code REV    ( a -- b ) \ Byte reverse in whole word
    tos tos rev,        \ 1 - reverse all bytes
    next,               \ 6
end-code


\ wo 03jan2023 Bit manipulation:
\ BITMASK *BIS  *BIC  *BIX  BIT* **BIS **BIC **BIX  BIT**
extra: code BITMASK ( +n -- bitmask )   \ Bit-nr to bit mask
    day 1 # movs,
    day tos lsls,
    tos day mov,
    next,
end-code

\ 8-bit variants
extra: code *BIS   ( mask a -- )
    day  sp )+ ldr,     \ 2
    sun  tos ) ldrb,    \ 2
    sun day orrs,       \ 1
    sun  tos ) strb,    \ 2
    tos  sp )+ ldr,     \ 2
    next,               \ 6
end-code
extra: code *BIC   ( mask a -- )
    day  sp )+ ldr,     \ 2
    day day mvns,       \ 1
    sun  tos ) ldrb,    \ 2
    sun day ands,       \ 1
    sun  tos ) strb,    \ 2
    tos  sp )+ ldr,     \ 2
    next,               \ 6
end-code
extra: code *BIX   ( mask a -- )
    day  sp )+ ldr,     \ 2
    sun  tos ) ldrb,    \ 2
    sun day eors,       \ 1
    sun  tos ) strb,    \ 2
    tos  sp )+ ldr,     \ 2
    next,               \ 6
end-code
extra: code BIT*   ( mask a -- 0|b )
    day  sp )+ ldr,     \ 2
    tos  tos ) ldrb,    \ 2
    tos day ands,       \ 1
    next,               \ 6
end-code

\ 32-bit variants (nog Poort variant erbij maken)
extra: code **BIS  ( mask a -- )
    day  sp )+ ldr,     \ 2
    sun  tos ) ldr,     \ 2
    sun day orrs,       \ 1
    sun  tos ) str,     \ 2
    tos  sp )+ ldr,     \ 2
    next,               \ 6
end-code
extra: code **BIC  ( mask a -- )
    day  sp )+ ldr,     \ 2
    day day mvns,       \ 1
    sun  tos ) ldr,     \ 2
    sun day ands,       \ 1
    sun  tos ) str,     \ 2
    tos  sp )+ ldr,     \ 2
    next,               \ 6
end-code
extra: code **BIX  ( mask a -- )
    day  sp )+ ldr,     \ 2
    sun  tos ) ldr,     \ 2
    sun day eors,       \ 1
    sun  tos ) str,     \ 2
    tos  sp )+ ldr,     \ 2
    next,               \ 6
end-code
extra: code BIT**  ( mask a -- 0|b )
    day  sp )+ ldr,     \ 2
    tos  tos ) ldr,     \ 2
    tos day ands,       \ 1
    next,               \ 6
end-code


\ wo 03jan2023 Aritmetic:
\ 1+  1-  2*  2/  U2/  +  - D2*  D2/  DU2/
\ NEGATE  ?NEGATE  ABS  DNEGATE ?DNEGATE  DABS  D+
forth: code 1+      ( a -- a+1 )    tos 1 # adds, next, end-code
forth: code 1-      ( a -- a+1 )    tos 1 # subs, next, end-code
forth: code 2*      ( a -- b )      tos tos add, next, end-code
forth: code 2/      ( a -- b )      tos 1 # asrs, next, end-code
extra: code U2/     ( a -- b )      tos 1 # lsrs, next, end-code

forth: code +      ( a b -- c ) \ ok
    day  sp )+ ldr,     \ 2 - Pop second stack item to R5
    tos day adds,       \ 1 - Add R5 to TOS
    next,               \ 6
end-code
forth: code -      ( a b -- c ) \ ok
    day  sp )+ ldr,      \ 2 - Pop second stack item to R5
    tos day tos subs.mv, \ 1 - Subtract TOS from DAY
    next,                \ 6
end-code

forth: code D2*    ( da -- db ) \ ok
    day  sp ) ldr,
    day day adds,       \ lo
    tos tos adcs,       \ hi
    day  sp ) str,
    next,
end-code
forth: code D2/    ( da -- db ) \ ok
    day  sp ) ldr,
    sun tos 1F # lsls.mv,
    tos 1 # asrs,
    day 1 # lsrs,
    day sun orrs,
    day  sp ) str,
    next,
end-code
extra: code DU2/   ( da -- db ) \ ok
    day  sp ) ldr,
    sun tos 1F # lsls.mv,
    tos 1 # lsrs,
    day 1 # lsrs,
    day sun orrs,
    day  sp ) str,
    next,
end-code

forth: code NEGATE ( a -- b ) \ ok
label-amsterdam
    tos tos neg,
    next,
end-code
extra: code ?NEGATE ( a b -- c ) \ ok
    day tos mov,
    tos  sp )+ ldr,
    day 0 # cmp,
    amsterdam 77  neg? no until,
    next,
end-code
forth: code ABS    ( a -- b ) \ ok
    tos tos tst,
    amsterdam 77  neg? no until,
    next,
end-code

forth: code DNEGATE ( da -- db ) \ ok
label-amsterdam
    day  sp ) ldr,
    sun 0 # movs,
    day day mvns,
    tos tos mvns,
    day 1 # adds,
    tos sun adcs,
    day  sp ) str,
    next,
end-code
extra: code ?DNEGATE ( da b -- dc ) \ ok
    day tos mov,
    tos  sp )+ ldr,
    day 0 # cmp,
    amsterdam 77 neg? no until,
    next,
end-code
forth: code DABS   ( da -- db ) \ ok
    tos tos tst,
    amsterdam 77 neg? no until,
    next,
end-code

forth: code D+     ( da db -- dc ) \ ok
    sp  { day sun moon } ldm, \ 4 - Day=bl Sun=ah Moon=al
    moon day adds,          \ 1 - lc
    tos sun adcs,           \ 1 - hc
    sp 4 # subs,            \ 1
    moon  sp ) str,         \ 2
    next,
end-code


\ ---- M*  DU*S  FM/MOD  SM/REM  /MOD  /  MOD  */MOD  */
forth: code M*     ( n1 n2 -- d )  \ Mixed *
    hop  sp ) ldr,
    hop tos hop tos smull,
    hop  sp ) str,
    next,
end-code

extra: : DU*S    ( xlo xhi y -- zlo zhi )
    tuck um*  drop >r       \ xlo y r: xhi*y
    um*  r> + ;

forth: : FM/MOD ( d1 n1 -- n2 n3 )
    >r tuck                 \ dhi dlo dhi
    dabs r@ abs um/mod      \ dhi r quot
    swap r@ ?negate         \ dhi quot r*
    swap rot r@ xor 0<      \ r quot neg?
    if  negate over         \ r quot* r
        if  1-              \ r quot-1
            r@ rot - swap   \ n-r quot-1
        then
    then
    rdrop ;

\ forth: : /MOD   >r s>d r> fm/mod ;
forth: code /MOD    ( x y -- mod q )    \ Floored division: Chapter 2.3.1.5?
    day  sp ) ldr,
    sun day tos sdiv,
    day sun tos day mls,
    tos sun movs,
    day  sp ) str,
    next,
end-code
forth: code /      ( +n1 +n2 -- q )
    day  sp )+ ldr,
    tos day tos sdiv,
    next,
end-code
forth: code MOD    ( n1 n2 -- r )
    day  sp )+ ldr,
    sun day tos sdiv,
    tos sun tos day mls,
    next,
end-code

forth: : */MOD  >r m* r> fm/mod ;
forth: : */     */mod nip ;

inside: : >UART     ( offset -- a )    [ cfg> cell+ ] literal @ + ;

\ wo 03jan2023: FILL  MOVE  BOUNDS  SKIP  SCAN  S<>
forth: code FILL       ( a u b -- )        \ ok
    sp { day sun } ldm,     \ 3 - DAY = u, SUN = a
    begin,
    day nzr? while,         \ 2 - u not zero?
        tos  sun ) strb,    \ 2 - Store b
        day 1 # subs,       \ 1 - Decrease u
        sun 1 # adds,       \ 1 - Increase a
    repeat,                 \ 2
    tos sp )+ ldr,          \ 2 - Replace TOS
    next,                   \ 6
end-code

forth: code MOVE       ( a1 a2 u -- )      \ ok
    sp  { sun moon } ldm,       \ 3 - SUN = a2, MOON = a1
    tos nzr? if,                \ 3 - u not zero?
        moon sun cmp,  u>? if,  \ 3 - Start at front?
        begin,
            day  moon ) ldrb,   \ 2 - Read byte from a1
            day  sun ) strb,    \ 2 - Store byte to a2
            moon 1 # adds,      \ 1 - Incr. a1
            sun 1 # adds,       \ 1 - Incr. a2
            tos 1 # subs,       \ 1 - Decr. n
        =? until,               \ 2 - Ready when u = 0
        tos sp )+ ldr,  next,   \ 8
        then,
        sun tos adds,           \ 1 - a2 to beyond end
        moon tos adds,          \ 1 - a1 to beyond end
        begin,
            moon 1 # subs,      \ 1 - Decr. a1
            day  moon ) ldrb,   \ 2 - Read byte from a1
            sun 1 # subs,       \ 1 - Decr. a2
            day  sun ) strb,    \ 2 - Store byte to a2
            tos 1 # subs,       \ 1 - Decr. n
        =? until,               \ 2 - Ready when u = 0
    then,
    tos  sp )+ ldr,             \ 2 - Ready replace TOS
    next,                       \ 6
end-code

extra: code BOUNDS ( a u -- a+u a )
    day  sp ) ldr,      \ 2
    tos day add,        \ 1
    tos  sp ) str,      \ 2
    tos day mov,        \ 1
    next,               \ 6
end-code

extra: code SKIP       ( ea a1 c -- ea a2 )
    day tos mov,            \ 1 - Save c in DAY
    tos  sp )+ ldr,         \ 2 - a1 to TOS
    moon  sp ) ldr,         \ 2 - ea to MOON
    ahead,  begin,          \ 2 - Jump to start point
        sun  tos ) ldrb,    \ 2 - Fetch char
        sun day cmp,        \ 1 - Equal to c
    =? while,               \ 2 - Yes?
        tos 1 # adds,       \ 1 - to next char
    2ROT  then,             \     Entry point
        moon tos cmp,       \ 1 - End reached?
    u>? no until,           \ 2 - Yes ready
    then,
    next,                   \ 6
end-code
extra: code SCAN       ( ea a1 c -- ea a2 )
    day tos mov,            \ 1 - Save c
    tos  sp )+ ldr,         \ 2 - a1 to TOS
    moon  sp ) ldr,         \ 2 - ea to MOON
    ahead,  begin,          \ 2 - Jump to start point
        sun  tos ) ldrb,    \ 2 - Fetch char
        sun day cmp,        \ 1 - Equal to c
    =? no while,            \ 2 - No?
        tos 1 # adds,       \ 1 - to next char
    2ROT  then,             \     Entry point
        moon tos cmp,       \ 1 - End reached?
    u>? no until,           \ 2 - Yes ready
    then,
    next,                   \ 6
end-code

extra: code S<>        ( a1 n1 a2 n2 -- f ) \ ok
    sp { hop day sun } ldm, \ 4 - HOP = a2, DAY = n1, SUN = a1
    moon tos mov,           \ 1
    tos tos eors,           \ 1
    tos 1 # subs,           \ 1
    day moon cmp,           \ 1
    =? if,                  \ 2
        day nzr? if,        \ 1
        begin,
            moon sun ) ldrb,    \ 2
            w  hop ) ldrb,      \ 2
            sun 1 # adds,       \ 1
            hop 1 # adds,       \ 1
            moon w cmp,         \ 1
        =? while,               \ 2
            day 1 # subs,       \ 1
        =? until,               \ 2
            tos 1 # adds,       \ 1
           then,
        then,
    then,
    next,               \ 6
end-code

\ wo 05jan2023: CATCH  THROW  ABORT  ?ABORT etc.
inside: : {FLY  adr fp to cp   flybuf/ to border ;
inside: : FLY}  [ ramadr: dp ] literal to cp   flybuf to border ;

forth: code THROW  ( n -- )  ( W.O. was 90 nu ~80 bytes )
    tos zer? if,  tos sp )+ ldr,  next,  then,
label-amsterdam
    pool,   lastname ,
            label-nocatchframe  -1 ,
    then,
    hop TP mov,
    sun hop his: r0 #) ldr, \ Read R0 to SUN
    rp 4 # subs,
    begin,
        rp 4 # add,
        sun rp cmp,          \ R0 rp u>
    u>? while,
        day  rp ) ldr,
        day rp cmp,
    =? until,               \ Frame found!
        sp  rp 4 #) ldr,    \ Restore SP & IP
        ip  rp 8 #) ldr,
        rp 0C # add,
        next,
    then,
    sp  hop his: s0 #) ldr, \ SP = value of S0
    rp sun mov,             \ Restore RP
    tos tos eors,           \ False flag
    tos  sp -) str,         \ Save TOS
    tos  w )+ ldr,          \ Should be last name
    ip   w ) ldr,           \ Jump to nocatchframe in QUIT
    next,
end-code

extra: create ?ABORT immediate NONAME
    tos zer? if,            \ False flag?
        tos  sp )+ ldr,     \ Pop TOS
        ip 4 # adds,        \ Skip inline address
        next,
    then,
    ip  { w } ldm,          \ IP@+ read throw NFA
    tos w mov,
    amsterdam 77 again,     \ THROW
end-code

\ : CATCH   ( xt -- )   {CATCH execute CATCH} ;
    align,              \ Optional align
LABEL-AMSTERDAM         \ headerless code {CATCH        \ a(((
( rom ) chere cell+ doer,
    rp 8 # subs,        \ Reserve stack frame
    sp  rp 4 #) str,    \ Push SP
    sun rp mov,         \ Push RP
    sun  rp ) str,
    next,

    align,              \ Optional align
LABEL-ROTTERDAM         \ headerless code CATCH}        \ r(((
( rom ) chere cell+ doer,
    rp 8 # add,         \ Remove stack frame
    tos  sp -) str,     \ Save TOS
    tos 0 # movs,       \ TOS = 0
    next,

forth: : CATCH
    [ AMSTERDAM compile, ]                              \ a)))
    execute
    [ ROTTERDAM compile, ] ;                            \ r)))

forth: : ABORT  ( ? -- )    true throw (;)
\ <><>

extra: code LFA>    ( lfa -- cfa )
    tos 5 # adds,       \ 1 - LFA>N
    day  tos ) ldrb,    \ 2 - Count
    tos 1 # adds,       \ 1
    sun 1F # movs,      \ 1 - Keep length only
    day sun ands,       \ 1
    tos day adds,       \ 1 - Skip string
label-amsterdam
    tos 3 # adds,       \ 1 - Cell align address
    sun 4 # movs,       \ 1
    sun sun neg,        \ 1
    tos sun ands,       \ 1
    next,
end-code
forth: header ALIGNED   AMSTERDAM doer,         \ a)))

forth: : HERE ( -- a )          cp @ ;
extra: : CHERE ( -- a )         cp @ ;                \ 15-02-2024

inside: : UALLOT  ( n -- )      uhere over + origin u> ?abort  +to uhere ;
inside: : CHERE? ( n -- n )     here over + border u> ?abort ;
forth: : ALLOT  ( n -- )        chere?  cp +! ;
forth: : ,    ( x -- )          here  cell allot  ! ;
extra: : H,   ( x -- )          here  2 allot    h! ;
forth: : C, ( byte -- )         here  1 allot    c! ;
forth: : COMPILE,  ( x -- )     , ;

extra: : PLACE  ( a n a2 -- )   \ store a,n as counted string at a2
    2dup c! 1+ swap move ;

\ move n bytes alligned to DP, no count.
extra: : M, ( a n -- )  for count c, next drop ; \ needs alignment
extra: : HALIGN ( -- )  here 1 and if true c, then ;
forth: : ALIGN  ( -- )  halign  here 2 and if true h, then ;

extra: code LFA>N ( lfa -- nfa )    tos 5 # adds, next,  end-code
forth: code >BODY      ( cfa -- pfa )                           \ ok
label-amsterdam  tos 4 # adds,  next,  end-code                 \ a(((
forth: header CELL+  ( a -- a+4 )   AMSTERDAM doer,             \ a)))
extra: code CELL- ( a -- a-4 )      tos 4 # subs, next,  end-code
forth: code CELLS ( n1 -- n2 )      tos 2 # lsls, next,  end-code

inside: : ?FHERE ( n -- fp )    \ is er ruimte voor n+1 bytes?  \ an02
    fp aligned dup >r
    + flybuf/ u<
    if r> else rdrop flybuf then
    dup to fp ;

\ Copy counted string to flybuffer
inside: : >FHERE ( a n -- a2 ) dup ?FHERE dup >r place r> ; \ an02


\ msb=1 -> IMMEDIATE,  msb=0 -> not IMMEDIATE
inside: : @IMM ( lfa -- 1|-1 )  lfa>n c@ 80 and 0= 2* 1+ ;
inside: : @HOM ( lfa -- f )     cell+ c@ 80 < ;     \ True = Not unique
inside: : @VOC ( lfa -- wid )   cell+ c@ 7F and ;   \ Voc. number
\ <><>


\ --- input/output ---
forth: : KEY    ( -- c )    'key  execute ;
forth: : KEY?   ( -- f )    'key? execute ;
forth: : EMIT   ( c -- )    dup 8 = 2* 1+ +to hor  'emit execute ;
forth: : CR     ( -- )      [ 0A 0D ] 2literal emit emit  false to hor  incr ver ;
forth: : SPACE  ( -- )      bl emit ;
forth: : SPACES ( n -- )    FOR space NEXT ;
forth: : TYPE   ( a n -- )  FOR count emit NEXT drop ;

inside: : .ACK   ok C000 and 8000 = if  6 emit then ;
inside: : .NAK   ok C000 and 8000 = if 15 emit then ;
inside: : .XON   ok 4000 and if  11 emit then ;
inside: : .XOFF  ok 4000 and if  13 emit then ;

\ wo 06jan2023 --- number output ---
\ extra: : >DIG   ( n -- ch ) dup 0A < 7 and + [char] 0 + ;
extra: code >DIG   ( n -- ch ) \ Number to char. \ ok
    day 0A # movs,      \ 1 - DAY = 10
    day tos cmp,        \ 1 - DAY u<= n
    u>? no if,          \ 2 - Yes,
        tos 7 # adds,   \ 1 - Add 7 to n
    then,
    tos char 0 # adds,  \ 1 - Add char 0 to it
    next,               \ 6
end-code

inside: code GNIRTS     ( a n -- )  \ Reverse string    \ ok
    sun  sp )+ ldr,         \ 2 - SUN = a
    moon sun tos adds.mv,   \ 1 - Add 'a' & 'u' to MOON
    moon 1 # subs,          \ 1 - MOON points to last char
    ahead,  begin,          \ 2 - Jump to start point
        day  sun ) ldrb,    \ 2 - Read front char
        tos  moon ) ldrb,   \ 2 - Read end char
        tos  sun ) strb,    \ 2 - Store end at front
        sun 1 # adds,       \ 1 - To next char
        day  moon ) strb,   \ 2 - Store front at end
        moon 1 # subs,      \ 1 - To previous char
    2SWAP then,             \     Entry point
        moon sun cmp,       \ 1 - Compare addresses
    u>? no until,           \ 2 - MOON u<= SUN
    tos  sp )+ ldr,         \ 2 - Ready, pop TOS
    next,                   \ 6
end-code

forth: : <#     ( -- )          40 ?fhere to hld ;  \ an02
forth: : HOLD   ( ch -- )       hld c! 1 +to hld ;
forth: : SIGN   ( hi -- )       0< if [char] - hold then ;
forth: : #      ( lo hi -- lo2 hi2 )    base @ du/s >dig hold ;
forth: : #S     ( lo hi -- 0 0 )        begin # 2dup or 0= until ;
forth: : #>     ( lo hi -- a n )        2drop fp hld over - 2dup gnirts ;
extra: : DU.STR ( du -- a n )   <# #s #> ;
extra: : D.STR  ( dn -- a n )   tuck dabs <# #s rot sign #> ;
extra: : RTYPE  ( a n r -- )    2dup min - spaces type ;
extra: : DU.    ( du -- )       du.str type space ;
forth: : D.     ( d -- )        d.str   type space ;
forth: : U.     ( u -- )        false du. ;
forth: : .      ( n -- )        s>d d. ;
forth: : U.R    ( u r -- )      >r false du.str r> rtype ;
forth: : .R     ( n r -- )      >r s>d d.str   r> rtype ;

forth: : DECIMAL    0A base ! ;
forth: : HEX        10 base ! ;
\ <><>

inside: : !INPUT    ( ib   #ib^>in@   source-id -- )
    to source-id  H-H >in !   to #ib   to ib ;
inside: : @INPUT    ( -- ib   #ib^>in@   source-id )
    ib   #ib >in @ H+H   source-id ;

forth: code /STRING    ( a n i -- a+i n-i ) \ ok
    day  sp 4 #) ldr,    \ 2 - DAY=a
    day tos adds,        \ 1 - DAY=a+i
    day  sp 4 #) str,    \ 2 - Store a+i
    day  sp )+ ldr,      \ 2 - DAY=n
    tos day tos subs.mv, \ 1 - TOS=n-i
    next,                \ 6
end-code

extra: code UPC    ( ch -- CH ) \ ok
    day char a # movs,      \ 1 - DAY = a
    day tos cmp,            \ 1 - a <= TOS
    >? no if,               \ 2 - Yes,
        day char z # movs,  \ 1 - Day = z
        tos day cmp,        \ 1 - z u<= TOS
        u>? no if,          \ 2 - Yes,
            day 20 # movs,  \ 1 - Make uppercase
            tos day eors,   \ 1
        then,
    then,
    next,                   \ 6
end-code

extra: : UPPER ( a n -- )
    bounds ?do  i c@ upc i c!  loop ;

extra: code ?STACK     ( -- )
    ]  true ?abort  [
code>
    sun TP mov,                                 \ 1 - Task base address
    day  sun  his: s0 #) ldr,                   \ 2 - Read S0 to DAY
    sp day cmp,  u>? no if,                     \ 3 - No SP underflow?
        day  sun  his: r0 #) ldr,               \ 2 - Read R0 to DAY
        sp day cmp,  u>? if,                    \ 3 - No SP overflow?
            rp day cmp,  u>? no if,             \ 3 - No RP underflow?
                day  sun  his: flybuf/ #) ldr,  \ 2 - Read FLYBUF/ to DAY
                rp day cmp,  u>? if,  next,     \ 3+6 - No RP overflow, ready!
    then,  then,  then,  then,
    ip w mov,                                   \ 1 - Jump to abort
    next,                                       \ 6
end-code

inside: : ?BASE ( -- )
    base @ [ 61 7 - 30 - 2 ] 2literal within
    if  hex  true ?abort  then ;
extra: : ?COMP      ( -- )  state @ 0= ?abort ;
\ <><>

inside: code INL#   ( -- x )    \ Read literal from inline address
    tos  sp -) str,     \ 3 - Save TOS
    day  rp ) ldr,      \ 2 - Read addr. of number
    day  { tos } ldm,   \ 2 - Fetch number & increase addr.
    day  rp ) str,      \ 2 - Skip number
    next,               \ 6
end-code
inside: code INLS   ( -- csa )  \ For counted string address
    tos  sp -) str,     \ 3 - Save TOS
    tos  rp ) ldr,      \ 2 - Read addr. of string to TOS           tos=a, day=count
    day  tos ) ldrb,    \ 2 - Fetch count                           day=day+tos
    day tos adds,       \ 1 - String end - 1                        day=day+4
    day 4 # adds,       \ 1 - Round end to next aligned address
    sun 4 # movs,       \ 1 - Make -4                               sun=-4
    sun sun neg,        \ 1 -
    day sun ands,       \ 1 - Cut string at 32-bits
    day  rp ) str,      \ 2 - Skip string
    next,               \ 6
end-code

forth: create POSTPONE immediate   :NONAME inl# compile, ;
forth: : RECURSE       ( -- )
    ?comp S0 @  ?dup 0= ?abort  compile, ; immediate

forth: : [ ( -- )   false state ! ; IMMEDIATE
forth: : ] ( -- )   true state ! ;

\ FLYER for state smart words
extra: : FLYER         ( -- )
    state @ ?EXIT
    20 ?fhere r> 2>r    \ Address of temp. hi-level code an02
    {FLY                \ Set here to fhere
    ] dive              \ Continue caller in Fly-mode, then return here.
    postpone EXIT       \ Close temp. code with an EXIT.
    postpone [ FLY}     \ Stop compiling & repair HERE
    ;                   \ This EXIT jumps to the temp. code

forth: code DEPTH  ( -- n ) \ ok
    day TP mov,             \ 1 -
    day day his: s0 #) ldr, \ 2 - Fetch stack base
    day sp subs,            \ 1 - Calc. used stack space
    tos  sp -) str,         \ 3 - Save TOS
    tos day mov,            \ 1 - Used space to TOS
    tos 2 # asrs,           \ 1 - Divide by 4
    next,                   \ 6
end-code

forth: create C" immediate :noname inls ;
forth: create S" immediate :noname inls count ;
forth: create ." immediate :noname inls count type ;

forth: : ACCEPT     ( a n -- n2 )
    over + >r               \ s: a r: enda
    dup                     \ s: a a2           \ starta & actual-position
    begin
        begin
            key dup 80 and while drop repeat
        0D over -           \ s: a a2 c f       \ continue?
    while 8 over =          \ s: a a2 c f       \ backspace?
        if  drop 2dup u<    \ s: a a2 f         \ not 1st position?
            if  1- ." k m"      \ becomes 3 8 20 8
                [ 8 chere 3 - c!
                  8 chere 1 - c! ]
            then                \ s: a a2-
        else over r@ u<         \ s: a a2 c f   \ enough space?
            if  bl max
                echo if dup emit
                then    over c!
                1+ dup          \ a a2+ x
            then drop           \ a a2
        then
    repeat rdrop drop - negate ; \ n2

0 [if]
inside: : R? R0 rp@ - 24 - ;    \ n
[else]
inside: code R?     ( -- n )
    tos sp -) str,
    day TP mov,
    tos  day his: r0 #) ldr,
    day rp mov,
    tos day subs,
    tos 20 # subs,
    next,
end-code
[then]

inside: : .OK   ( -- )
    ?base  ?stack  err? 0=
    if  ok 1 and
        if  state @ if ."  ok" else ."  OK" then        \ OK
        then
        ok 2 and
        if  ." ." depth [char] 0 + emit                 \ depth
        then
    then   cr                                           \ cr always
    state @ 0=
    if  ok 4 and
        if  r? ?dup if false > 2* [char] - + emit then  \ type "+" or "-"
            base @ [char] 0 + emit ." )"                \ base
        then
    then   false to err? ;

forth: : REFILL ( -- t/f )
    false  source-id true = ?exit           \ -1  EVALUATE
    source-id 0= if                         \ 0   Terminal input
        >in !  .ok  .ack  .xon
        tib tib/ tib - accept  to #ib  space
        .xoff  true exit
    then
    drop  source-id &REFILL execute ;       \ 0> Special refill cases

chere refill-vec !
:noname     ?abort ;

\ : PAREA ( -- a2 a1 ) #ib >in @ ib dup d+ ;
extra: code PAREA      ( -- a2 a1 )        \ ok
    ramadr: >in , \ Pointer >IN
code>
    sp 8 # subs,        \ 1
    tos  sp 4 #) str,   \ 2
    w  w ) ldr,         \ 2
    tos  w ) ldr,       \ 2  >IN @
    day  w 4 #) ldr,    \ 2  #IB @
    sun  w 8 #) ldr,    \ 2  IB @
    tos sun adds,       \ 1  Start address
    day sun adds,       \ 1  End address
    day  sp ) str,      \ 2
    next,               \ 6
end-code

forth: : PARSE  ( ch -- a n )       \ no refill
    >r parea tuck           \ from input-end from
    r> scan tuck            \ from till input-end till
    1+ umin  ib - >in !   \ over the delimiter
    over - ;

inside: : BL- ( -- )        \ skip spaces, with refill
    begin   parea bl skip
            dup ib - >in !    \ input-end string-address
            =                   \ nulstring?
    while refill 0=
    until
    then ;

extra: : BL-WORD ( -- csa )     \ with refill, 16
    bl-  bl parse  >fhere ;

extra: : BEYOND ( ch -- )       \ with refill, 19
    >r
    begin   parea r@ scan
            tuck =              \ eol?
    while   drop REFILL         \ r: delimiter
            0= ?abort
    repeat
    rdrop
    1+ ib - >in ! ;             \ over the delimiter

forth: : CHAR ( <name> -- ch )  bl-word count 0= ?abort c@ ;
forth: : (      [char] )    beyond ; IMMEDIATE
forth: : .(     ( text -- ) [char] ) parse type ; IMMEDIATE

\ print something between parenthesis
extra: : (.)    ( -- )  ." (" dive ." )" ;
\ <><>

\ --- Inputstream ---
\ : THREAD ( bl-word -- adr )   \ thread addr
\       count swap c@ xor dict-threads 1- and 2* HOT + ;
inside: code THREAD     ( bl-word -- adr ) \ thread addr
    hot ,   \ Threads start address
code>
    day  tos ) ldrb,    \ DAY=len
    tos  tos 1 #) ldrb, \ TOS=c
    tos day eors,       \ TOS=c|len
    sun dict-threads 1- # movs, \ SUN=mask
    tos sun ands,       \ TOS=+n
    tos 2 # lsls,       \ TOS=+n*4
    day  w ) ldr,       \ DAY=hot
    tos day adds,       \ TOS=hot+n*4 = link address
    next,
end-code

{{+ inside: : NAME?         ( csa lfa -- csa lfa2|0 )
    begin
        dup
    while 2dup
        lfa>n count 1F and  \ csa lfa csa name count
        rot count           \ csa lfa name count sa count
        s<>                 \ csa lfa <>?
    while lnk@          \ csa lfa@      \ lnk@
    again
    then
    then ;
inside: : FIND) ( csa v0 vp -- wa 0 | xt imm )  \ 56
    2>r false over      \ csa 0   csa  r: v0 vp
    dup count upper     \ ..  ..  ..
    dup thread @        \ ..  ..  .. lfa
    2r> 2swap           \ ..  ..  v0 vp  csa lfa
    begin
        name?           \ ..  ..  .. ..  ..  lfa|0  \ name found?
        2>r             \ ..  ..  .. ..             r: csa lfa|0
        r@
    while               \ ..  ..  .. ..             r: csa lfa
        tuck r@ @voc    \ ..  ..  vp v0 vp wid
        scan            \ ..  ..  .. .. vx      ( end adr1 ch -- end adr2 )
        tuck <>         \ ..  ..  vp vx ?       \ wid in order?
        if  2nip 2r@    \ vp vx csa lfa             r: csa lfa
            2swap       \ csa lfa vp vx
        then
        swap            \ csa lfa vx vp         \ wid not found
        r@ @hom         \ ..  ..  .. ..         \ homonyms?
    while
        2dup <>         \                       r: csa lfa  \ order not empty?
    while 2r>
    lnk@            \ ..  ..  vx vp  csa lfa'|0     r: -      \ lnk@
    again
    then then then      \ ..  ..  v0 vp         r: csa lfa'|
    2r> 2drop 2drop     \ csa 0|lfa             r: -
    dup                                     \ found?
    if  nip             \ lfa
        dup lfa>        \ lfa cfa
        swap @imm       \ cfa imm
    then ;              \ cfa imm | csa 0

forth: : FIND   ( csa -- wa 0 | xt imm )
    v0 vp find) ;
}}

{{- forth: : FIND ( csa -- wa 0 | xt imm )  \ 56
    dup count upper     \ csa
    dup thread @        \ csa lfa
    begin dup
        while 2dup
            lfa>n count 1F and  \ csa lfa csa name count
            rot count           \ csa lfa name count sa count
            s<>                 \ csa lfa <>?
        while lnk@          \ csa lfa@      \ lnk@
    again
        then
        then
    dup                                     \ found?
    if  nip             \ lfa
        dup lfa>        \ lfa cfa
        swap @imm       \ cfa imm
    then ;              \ cfa imm | csa 0
}}

\ --- string>number ---
extra: code DIG?   ( ch base@ -- n true | ch false ) \ Char. to number \ ok
    w  sp ) ldr,            \ 2  W = ch
    day tos mov,            \ 1  DAY = base@
    tos 0 # movs,           \ 1  TOS = 0
    sun char 9 # movs,      \ 1  SUN = 9
    w sun cmp,  u>? if,     \ 3  ch 9 u>
        sun char A # movs,  \ 1  SUN = 'A'
        sun w cmp,  u>? if, \ 3  'A' ch u>
            next,           \ 6  Ready
        then,
        w 7 # subs,         \ 1  Adjust ch
    then,
    sun 30 # movs,          \ 1  SUN = '0'
    w sun subs,             \ 1  ch - '0'
    day w cmp,  u>? if,     \ 3  base@ dig u>
        w  sp ) str,        \ 2  Save digit
        tos 1 # subs,       \ 1  and true
    then,
    next,                   \ 6
end-code

forth: : >NUMBER    ( ulo uhi a n -- ulo uhi a n )  \ string>number
   begin dup
    while over c@ base @ dig?
        0= if drop EXIT then
        >r 2swap base @
        du*s
        r> false d+ 2swap
        1 /string
    repeat ;

inside: : NUMBER? ( a n -- lo hi i )    \ i=0 sn,  i=1 dn, i=-1 err
    2dup + 1- c@ [char] . =
    if 1- 1 else false then             >r  \ dn ?
    over c@ [char] - =
    if 1 /string true else false then   >r  \ 0< ?
    false over <
if over c@ [char] , <>
if false dup 2swap          \ lo=0 hi=0 a n
   begin >number dup
   while over c@ [char] , =
   while  1 /string dup 0=
   until then then nip
   0=
   if r> ?dnegate r> exit   \ ok
   then
then then rdrop rdrop true ;    \ error

extra: : DN
  bl-word count 2dup upper
  number? 0< ?abort postpone 2literal ; immediate

\ Make newest word findable. No problem if used twice on the same word.
extra: : REVEAL ( -- )  created dup LFA>N thread ! ;

\ a1 = interrupt routine address
\ a2 = address in interrupt vector table
extra: : VEC!   ( a1 a2 -- )    >r  1 or  r> ! ;
\ extra: code INT-ON     ( -- )      cpsie,  next, end-code
\ extra: code INT-OFF    ( -- )      cpsid,  next, end-code

extra: : IRQ!          ( a +n -- )  \ Set IRQ vector +n
    33 umin cells  40 +  ivecs +  vec! ;

inside: : TIDY  ( -- )  \ vectortest
    here 'emit u<   if ['] TEMIT to 'emit   then
    here 'key? u<   if ['] TKEY? to 'key?   then
    here 'key  u<   if ['] TKEY  to 'key    then
    here app   u<   if ['] NOOP  to app     then
    here &CONFIG u< if ['] NOOP  to &CONFIG then    \ Configuration vector
    here &REFILL u< if [ refill-vec @ ] literal to &REFILL then \ Refill vector
    here &FAULT  u< if ['] NOOP  to &FAULT  then    \ Hardfault vector
    main  begin                     \ Secure the forgetting of tasks!
        @ dup main <>               \ Next task is not main task?
    while
        dup his r0 @ cell-          \ Yes, get tasks XT address
        dup @  here u> if           \ Is tasks XT deleted?
            over sleep              \ Yes, put task asleep
            ['] noop  over !        \ Replace token with NOOP
        then  drop
        dup here u< 0= if           \ Is task forgotten? ( u>= )
            dup his flybuf @  to xhere \ Yes, release tasks memory
            dup @  main !           \ finally remove task from link chain
        then
    repeat  drop ;

\ Note that by storing the inverted checksum here the result must be zero
\ because it will be included in the total checksum
only: code CHK     ( -- u ) \ Check checksum of core, when u is 0 core is Ok
    origin ,            \ HOP = Begin address
    label-core  -1 ,    \ DAY = End address
    -1 ,                \ Inverted checksum
code>
    w  { hop day } ldm,
    tos  sp -) str,
    tos 0 # movs,       \ -1
    tos tos mvns,
    begin,
        hop { sun } ldm,
        tos sun eors,
        hop day cmp,
    =? until,
    next,
end-code

inside: : NUM? ( a n -- ? t/f ) \ true = error!
    number?  s>d ?exit
    if   postpone 2literal
    else drop  postpone literal
    then  false ;

extra: : WINTERPRET  ( i*x "name" -- j*x )
    bl-word dup c@
    if find dup if state @ = if , exit
                             then execute exit
                then drop count num? ?abort exit
    then drop ;

extra: : INTERPRET
BEGIN [ >BOX ]                                  \ (((
    bl-word dup c@ 0= if  drop exit  then       \ for EVALUATE
    find dup if
        state @ = if  compile,  [ BOX@ ] again  \ ) )
        then          execute   [ BOX@ ] again  \ ) )
    then
    drop count  num? ?abort
    [ BOX> ]  again (;)                         \ )))

forth: : MS  ( ms -- )          \ Millisecond delay
    3E8  begin [ >box ]  *      \ 1000 us for each step
    400B0028 @ >r               \ TIMERAWL  Timer0
    begin
        pause  400B0028 @ r@ -  \ us diff
    over u< 0= until r> 2drop ; \ Done when diff U>= us
extra: : US    ( us -- )    [ box@ swap cell+ swap ] again (;) \ Microseconds delay

inside: : SWALLOW   ( -- )      \ Ignore the rest of the file
    .nak  .xon  cr              \ Software handshakes
    begin
        1F4 for                 \ Max. EOL wait period of 160 ms
            140 us key? 0= while \ Still no key?
        next
            ." ."  cr  exit     \ Yes, show file finshed
        then    
        rdrop  ." ,"            \ No, show file skipping
        begin  key drop key? 0= until \ Drop all received keys
    again ;

inside: : !CREATED  ( -- )
    hot false
    [ dict-threads ] literal
    FOR >r @+ r> umax NEXT
    to created drop ;

forth: : QUIT   ( -- )
    cr  begin
        !R0 !created
        tib false dup ( ib #ib,>in@ source-id ) !input
        postpone [  fly}
        ['] INTERPRET  CATCH
        align   false to source-id
        dup -38 = if  drop  swallow  QUIT  then
        [ chere  nocatchframe ! ]  to err?      \ THROW emergency entry
        cr space ib #ib type                    \ Show line with error
        cr >in @ #ib over = - dup spaces ." \"  \ Print pointer
        cr 1+ spaces   err? true <>             \ Not abort?
        if  err? origin here within
            if  err? count over 1 and           \ odd string address?
                if    20 min                    \ abort"
                else  1F and ." Msg from "      \ ?abort nfa = odd
                then  type space
            then
            ." Error # " err? u.  err? .        \ throw# when not -1
        then
        swallow
    again (;)

{{+ inside: : ORDER,    ( -- )  \ compile order as counted string
        vp v0 1+ over -         \ a,n
        dup c, m, align ;
inside: : >ORDER        ( adr -- adr2 ) \ restore compiled order
        count                   \ a,n
        v0 1+ over -  to vp
        2dup vp swap move
        + aligned ;
forth: create VOCABULARY to-do:
    cell+ h@ vp c! ;    \ skip link

only:  0 vocabulary ONLY
only:  1 vocabulary FORTH
only:  2 vocabulary INSIDE
only:  3 vocabulary EXTRA
only:  4 vocabulary ASSEMBLER
only: : FRESH FFFFFFFF >order drop ;    \ patched by shield noforth
only: : ALSO
    7 v0 vp - < ?abort                      \ overflow?
    vp c@   true +to vp   vp c! ;
only: : PREVIOUS    v0 vp - 2 < ?abort incr vp ;    \ underflow?
only: : DEFINITIONS vp c@   v0 c! ;
}}

inside: : HEADER        \ The new word is not yet linked,
                        \ and has no CFA
                        \ REVEAL is done in ;  END-CODE  CREATE
    bl-word                \ csa (at fhere)
    dup c@ nn 20 1 within ?abort \ nul-string or too long
    dup count upper         \ csa
    dup thread @            \ lfa of previous word
    align  here to created \ for reveal
\ link
    dup compile,            \ csa lfa   \ write link
{{+ name? }}                \ csa name-exists?
{{- drop dup find nip }}    \ csa name-exists?
    if  space dup count type
        ."  is not new "
        false               \ name exists (homonym)
    else 80                 \ name is unique
    then
\ hvoc+count
{{+ v0 c@ or }}
    over c@                 \ csa hvoc count
    b+b h,                  \ csa
\ name
    count                   \ a +n
    m,  align ;             \ name, no codefield

\ CURTAIL cuts cell-link lists
inside: : CURTAIL   ( fence linkholder   --   ) \ See domarker
    tuck @      \ top-link
    ahead
    begin lnk@ ( lnk@ )
    /then
        2dup u>
    until                   \ linkholder fence link u>?
    nip swap ! ;

only: create SHIELD to-do:
BEGIN [ >BOX ]                              \ (((
{{+ >order }}
    here >r             \ Old HERE
    dup compile@  cp !  ( to dp )
    cell+ @ to uhere
    here  hot
    [ dict-threads
{{+ 2  }}   \ pfx-link and wid-link
{{- 1  }}   \ pfx-link
    + ] literal
    FOR 2dup curtail cell+ NEXT 2drop
    !created  tidy
    here  r> over -  FF fill ; \ Erase removed memory

only: create MARKER to-do:
[ BOX> ] again (;)                          \ )))

extra: : S?        ( -- f ) \ result = 0 when switch S2 is pressed
    0 cfg c@ bitmask  3 cfg @ bit** ; \ Read inputs & leave flag

extra: : .LOGO      ( -- )
    cr cr 1D dup spaces ." *"  cr
    cr 7 dup spaces ." *" dup spaces me count type spaces ." *"
    cr 11 spaces me2 count type
    cr cr spaces ." *" cr ;

extra: : GPIO!     ( mode io -- )  \ GPIO-pin to mode
    2* cells 40028004 + ! ; \ IO_BANK0_BASE     control register
extra: : PADS!     ( ctrl io -- )  \ GPIO-pin PAD-control
    cells 40038004 + ! ;    \ PADS_BANK0_BASE   pad control registers


\ Valid frequencies: 48, 96, 144, 192, 240, 288, 336, 384, 432 & 480MHz
inside: create MAX-CLK  ( -- a )    \ Clocks configuration
\   decimal 144000000 , \ Selected PLL clock 144MHz
\   hex          0B0 h, \ Core on 1.1 Volt
\               6042 h, \ PLL feedback divisor & post dividers (1152)
\           1  3  b+b , \ PERI=1 (144mhZ) & ADC/USB=3 dividers
\   decimal 240000000 , \ Selected PLL clock 240MHz
\   hex          0E0 h, \ Core now on 1.25 Volt
\               5041 h, \ PLL feedback divisor & post dividers
\           2  5  b+b , \ PERI=2 (120mhZ) & ADC/USB=5 dividers
                        \ USB & ADC clock need to be 48MHz
    decimal 384000000 , \ Selected PLL clock 384MHz     <---- Default version
    hex          110 h, \ Core now on 1.4 Volt
                8041 h, \ PLL feedback divisor & post dividers
            3  8  b+b , \ PERI=3 (128mhZ) & ADC/USB=8 dividers
                        \ USB & ADC clock need to be 48MHz
\   decimal 480000000 , \ Selected PLL clock 480Hz
\   hex          150 h, \ Core now on 1.7 Volt
\               5021 h, \ PLL feedback divisor & post dividers
\           4 0A  b+b , \ PERI=4 (120mhZ) & ADC/USB=10 dividers
                        \ USB & ADC clock need to be 48MHz

\ Change the core voltage of the RP2350
extra: : VCORE      ( +n --)
    5AFE0000 >r   r@ 50 or      \ Build access to core power supply
    40100004 !  dup 0F0 >       \ Do we need high voltage?
    100 and  A050 or            \ Build data pattern
    r@ or  40100004 !           \ Enable high/low voltage setting
    r> or  4010000C !           \ Change core voltage, default 0B = 1,1 Volt
    begin  8000 4010000C bit**  \ Core voltage stable?
    0= until ;                  \ Yes, ready


\ Set core voltage from MAX-CLK and leave PLL divider data
inside: : PLL>      ( -- post mul )
    MAX-CLK cell+ h@+ vcore     \ Set power supply setting
\   4010000C h@ umax  vcore     \ Use always the largest voltage
    h@ b-b >r  0C lshift  r> ;  \ Read & leave PLL settings

\ Change CPU klok, minimal valid frequency here is 10kHz, max.is the configured clock freq.
extra: : KHZ       ( kHz -- div )  \ Set scaled clock freq. in 1kHz steps
    MAX-CLK @  3E8 / >r      \ Freq. in kHz                     f1 fl
    r@ umin  0A umax  r>     \ Keep frequency in valid range    fn fl
    over 0A /  0 cfg 2 +  h! \ Store it in CFG in 10kHz steps   fn fl
    over /mod >r             \ Calc. q & remainder              fn r        q
    10000  rot */            \ Build fractional part            fraq        q
    r> h+h  40010040 ! ;     \ Set new freq.

\ From RP2350 datasheet page 971 ff.
\ Now more flexible to work for both UART's
inside: : BAUD   ( baud -- ) \ Set baudrate for UARTx
    10 * >r  MAX-CLK @+     \ Read PLL clock
    swap cell+ c@ /         \ Read divider & calc. peripheral clock freq.
    r@ /mod                 \ Calc. baudrate divisor
    swap 1+  40 r> */       \ Convert remainder to fraqtional part
    24 >uart >r             \ UART baudrate register-1
    r@ cell+ !  r@ !        \ Set baudrate
    70 r> cell+ cell+ ! ;   \ Do dummy LCR_H write


\ ************* Warm start of noForth **************

\ Ask for a ROMcall address using the lookup code in DAY
\ The ROMcall address is returned in the SUN register
inside: routine ROMCALL ( -- a ) \ In:  DAY=pointer to lookup string
label-amsterdam             \ Out: SUN=rom subroutine address
chere 77 >box
    { ip sp w tos lr } push, \ Save data for real function call
    ip  day ) ldrh,         \ IP = R0 = lookup code
    sp 4 # movs,            \ SP = R1 = ARM secure key
    w 0 # movs,             \  W = R2 = ROM base address
    hop  w 16 #) ldrh,      \ HOP = address of lookup subroutine
    hop blx,                \ Call lookup table
    sun ip mov,             \ Copy subr. address to SUN
    { ip sp w tos pc } pop, \ Restore data for function call
end-code

\ inside: code RESTORE-REGS   ( -- )
label-rotterdam \ Restore DOES register, etc.
pool,
    tp> ,       \ Task pointer address
    origin ,    \ DOES routine address
then,
    w  { hop day } ldm,
    TP hop mov,
    does day mov,
    next,
\ end-code

\ Enable write access to flash memory
inside: code {W         ( -- )
    char I c,  char F c,    \ Connect SSI to QSPI pads (1)
    char E c,  char X c,    \ Exit XIP mode (2)
code>
    hop does mov,           \ DOES to HOP
    { ip sp tos hop } push, \ These Forth registers are used in called code
    day w mov,              \ Command data address to DAY
    { day } push,           \ Save POOL pointer
    amsterdam bl,           \ Get address of ROM function
    sun blx,                \ Call Connect SSI function

    { day } pop,            \ Restore POOL pointer
    day 2 # adds,           \ To next command data address
    amsterdam bl,           \ Get ROM function address
    sun blx,                \ Call Exit XIP function
    { ip sp tos hop } pop,  \ Pop Forth registers
    rotterdam 77 again,     \ Restore DOES
end-code

\ Disable write access & enable XIP mode
inside: code W}         ( -- )
    char F c,  char C c,    \ Flush cache (1)
    char C c,  char X c,    \ Enter XIP mode (2)
code>
    hop does mov,           \ DOES to HOP
    { ip sp tos hop } push, \ These Forth registers are used in called code
    day w mov,              \ Command data address to DAY
    { day } push,           \ Save POOL pointer
    amsterdam bl,           \ Get address of ROM function
    sun blx,                \ Call connect SSI function

    { day } pop,            \ Restore POOL pointer
    day 2 # adds,           \ To next command data address
    amsterdam bl,           \ Get ROM function address
    sun blx,                \ Call enter XIP function
    { ip sp tos hop } pop,  \ Pop Forth registers
    rotterdam 77 again,     \ Restore DOES
end-code

\ Erase flash memory from 'roma' and '+n' bytes and '+n'
\ must be rounded upwards to the next erase-block size
inside: code WIPE-FLASH ( roma +n -- )
    1000 ,                  \ Erase block size
    char R c,  char E c,    \ Erase a Flash memory range
code>
    moon sp mov,            \ Save data stack pointer in MOON
    hop does mov,           \ DOES to HOP
    { ip sp tos hop } push, \ These Forth registers are used in called code
    day w mov,              \ Command data address from W to DAY
    day  { w } ldm,         \ Block size (#blk)
    sp tos mov,             \ Block byte count (+n)
    tos 20 # movs,          \ Command (e-cmd)
    moon { ip } ldm,        \ Start offset from start of FLASH (roma)
    amsterdam bl,           \ Get ROM function address
    sun blx,                \ Call ROM function
    { ip sp tos hop } pop,  \ Pop Forth registers
    sp 04 # adds,           \ Pop SP
    tos  sp )+ ldr,         \ Restore TOS
    rotterdam 77 again,     \ Restore DOES
end-code

\ Write '+n' bytes from 'rama' to 'roma' note that
\ '+n' must be rounded to the next 0x100 write page!
inside: code WRITE-FLASH ( roma rama +n -- )
    char R c,  char P c,    \ Write Flash memory range
code>
    moon sp mov,            \ Save data stack pointer in MOON
    hop does mov,           \ DOES to HOP
    { ip sp tos hop } push, \ These Forth registers are used in called code
    day w mov,              \ Command data address from W to DAY
    w tos mov,              \ Count to W
    moon { sp } ldm,        \ SP = Address end
    moon { ip } ldm,        \ IP = Address start
    amsterdam bl,           \ Get ROM function address
    sun blx,                \ Call ROM function
    { ip sp tos hop } pop,  \ Pop Forth registers
    sp 8 # adds,            \ Pop SP
    tos  sp )+ ldr,         \ Restore TOS
    rotterdam 77 again,     \ Restore DOES
end-code

inside: code SET-GPIO   ( -- )      \ GPIO 2 to 29 are inputs
    D0000000 ,      \ HOP  = SIO base
    40038004 ,      \ DAY  = GPIO0 pads register
    40028014 ,      \ SUN  = GPIO2 CTRL register
    cfg> ,          \ MOON = Start of CFG table
code>
    w  { hop day sun moon } ldm,
    w 1 # movs,             \ OE is LED output, others input
    moon  moon 1 #) ldrb,   \ MOON = LED GPIO-number
    { moon } push,          \ Save for later too
    w moon r) lsls,         \ W = GPIO bitmask for LED
    w  hop 30 #) str,       \ Set GPIO OE low on most inputs
    w w eors,
    w  hop 34 #) str,       \ High OE outputs too
    w  2D # movs,           \ 45
    moon 5 # movs,          \ Enable SIO
    begin,
        moon  sun ) str,    \ Set input
        sun 8 # adds,       \ To next CTRL register
        w 1 # subs,
    =? until,
    w 2F # movs,            \ 47 GPIO's to initialise
    moon 05B # movs,        \ GPIO's, isolation off, input enable,
    begin,                  \ pullup, schmitt trigger, fast slew rate
        moon  day ) str,    \ Set input
        day 4 # adds,       \ To next PADS register
        w 1 # subs,
    =? until,
\ Enable coprocessor P0
    hop  E000ED88 #w mov32,         \ CPACR  Enable access to copocessors
    day  hop ) ldr,
    w 3 # movs,                     \ CP0 full access
    day w orrs,
    day  hop ) str,
    dsb,                            \ Mandatory opcodes
    isb,
\ Led on
    { hop } pop,                    \ hop 19 # movs,
    w 1 # movs,
    0 4 hop w 0 mcrr,               \ Set GPIO_OUT high
    day FFFFF #w mov32,             \ Delay dm 1,000,000
    begin,  day 1 # subs, =? until,
    rotterdam 12 + 77 again, \ next,
end-code

inside: code CLK-ON     ( div offset -- )
    40013000 ,      \ HOP = Clocks base clear alias
    40010000 ,      \ DAY = Clocks base
    800 ,           \ SUN = Start/stop clock bit
code>
    w  { hop day sun } ldm,
    w  sp )+ ldr,           \ Get divisor
    w  10 # lsls,           \ Place in high 16-bits
    sun  hop tos r) str,    \ Stop clock
    moon 0B # movs,         \ Wait B00 ticks
    moon 8 # lsls,          \
    begin,  moon 1 # subs,  =? until,
    moon 20 # movs,         \ Select PLL_SYS
    moon  day tos r) str,   \ Set PLL_SYS
    sun moon adds,          \ Add PLL_SYS
    sun  day tos r) str,    \ Start clock
    tos 4 # adds,           \ Divisor register
    w  day tos r) str,      \ Set divisor
    tos sp )+ ldr,
    rotterdam 12 + 77 again, \ next,
end-code

\ Register aliases: 1000=Xor, 2000=Set, 3000=Clear
inside: code RESTART-DEVICES ( -- )
    1FFFFFF7 ,      \ W   = Reset almost all
    40020000 ,      \ HOP = RESETS_BASE
code>
    w  { w hop } ldm,               \ Read used data
    day  hop ) ldr,                 \ Read resets reg.
    day w bics,                     \ Clear almost all
    day  hop ) str,                 \ Write back
    begin,
        day  hop 8 #) ldr,          \ Read RESET_DONE
        day w ands,                 \ Mask bits to test
        day w cmp,                  \ Check if almost all are ready
    =? until,                       \ All done?
    rotterdam 12 + 77 again, \ next,
end-code

inside: code START-XOSC     ( -- )
    40010000 ,  \ Clocks base address (HOP)
    40048000 ,  \ X-oscillator base address (DAY)
    00FABAA0 ,  \ X-osc enable pattern (SUN)
    40013000 ,  \ Clocks base CLEAR-address  (MOON)
code>
    w  { hop day sun moon } ldm,
    w 2F # movs,            \ Init. Xosc, set down counter #47
    w  day 0C #) str,
    sun  day ) str,         \ Enable Xosc.
    begin,
        w  day 4 #) ldr,    \ Read Xosc. status
        w 0 # cmp,          \ Zero when Xosc. is stable
    <? until,
    w 60 # movs,            \ CLK_SYS = XOSC = 3
    w  hop 3C #) str,
    begin,
        w  hop 44 #) ldr,   \ Read selected clock back
        w 1 # cmp,          \ One means it's stable
    =? until,
    w 3 # movs,             \ Select PLL-USB as CLK_REF
    w  moon 30 #) str,
    begin,
        w  hop 38 #) ldr,   \ Read selected clock back
        w 1 # cmp,          \ One means it's stable
    =? until,
    rotterdam 12 + 77 again, \ next,
end-code

inside: code INIT-PLLS      ( post mul -- )  \ Initialise PLL's
    40050000 ,  \ HOP  = PLL sys base address
    40020000 ,  \ MOON = RESETS_BASE  Reset address
code>
    w { hop moon } ldm,     \ HOP = SYS base, MOON = RESETS_BASE
    w C000 # movw,          \ Reset both PLLs
    sun  moon ) ldr,        \ Read resets reg.
    sun w bics,             \ Clear PLLs bits
    sun  moon ) str,        \ Write back
    begin,
        sun  moon 8 #) ldr, \ Read RESET_DONE
        sun w ands,         \ Mask bits to test
        sun w cmp,          \ Check PLLs are ready
    =? until,               \ Both ready?
    moon 2D # movs,
    moon  hop 4 #) str,     \ PLL off
    tos  hop 8 #) str,      \ SYS = 12 x mul = 12*mul MHz
    tos sp )+ ldr,          \ TOS = post clock
    tos  hop 0C #) str,     \ Set PLL post dividers
    sun 0 # movs,           \ Power up PLL
    sun  hop 4 #) str,
    begin,                  \ Both PLL locked?
        moon  hop ) ldr,
        moon 0 # cmp,
    neg? until,             \ When highest bit is set
    tos sp )+ ldr,
    rotterdam 12 + 77 again, \ next,
end-code

inside: code INIT-CLKS    ( -- )
    40010000 ,  \ Clocks base address, W & SUN are scratch
    40013000 ,  \ Clocks base clear alias
code>
    w  { hop day } ldm,     \ HOP = 40008000, DAY = 4000B000
    w 1 # movs,             \ Clock sys to ref clock
    sun w 10 # lsls.mv,     \ Divider = 1
    w  day 3C #) str,       \ Clock source PLL USB
    begin,                  \ Wait for selected source (PLL)
        w  hop 44 #) ldr,   \ CLK_SYS_SELECTED
        w 1 # cmp,
    =? until,
    day 0 # movs,           \ MUX to PLL
    day  hop 3C #) str,
    w  hop 3C #) str,       \ CLK_SYS_CTRL
    sun  hop 40 #) str,     \ CLK_SYS_DIV
    rotterdam 12 + 77 again, \ next,
end-code

\ Divider is the divider for tick generator +n (is one of six)
\ A zero divider stops the selected tick generator
extra: code TICKS    ( divider +n -- )  ( 60 bytes )
    40108000 ,
code>
    tos 5 # cmp, u>? if,    \ Invalid ticks block?
        tos  sp 4 #) ldr,   \ Yes, remove data
        sp 8 # adds,    
        next,
    then,                   \ No, set ticks counter
    hop  w ) ldr,           \ Read TICKs base address
    w 0C # movs,            \ Calculate ticks timer offset
    tos w mul,
    hop tos adds,           \ Build TICKs timer address
    w 0 # movs,             \ Stop ticks timer
    w  hop ) str,
    dsb,                    \ Hold
    sun  sp )+ ldr,         \ Read new divider
    day FF # movs,          \ Max. divider = 255
    sun day ands,
    sun nzr? if,            \ Divider not zero, activate it
        sun  hop 4 #) str,  \ Set cycles divider
        dsb,                \ Hold
        w 1 # movs, 
        w  hop ) str,       \ Start ticks timer again
    then,
    tos  sp )+ ldr,         \ Pop stack
    next,
end-code


extra: code  LED   ( -- )
    cfg> ,
code>
    sun 1 # movs,               \ Set 1 in SUN
    w  w ) ldr,                 \ Read CFG address
    moon  w 1 #) ldrb,          \ Read LED nr. ( moon 19 # movs, \ Set GPIO25 in MOON )
    0 5 moon sun 0 mcrr,        \ Toggle GPIO_OUT (LED)
    next,
end-code


inside: : SET-UART  ( -- )  \ Initialise the UART & switch
    [ cfg> ] literal @+ h-h drop >r \ Save GPIO-pin number      cfg+4       IO-S?
    @+ 40078000 = abs >r    \ and UART number                   cfg+8       IO-S? 0|1    
    30 >uart                \ UART control register             cfg+8 adr   idem
    301 over **bic          \ Uart disable                      idem        idem
    swap @ baud             \ Set default baudrate              adr         idem
    301 swap ! \ set-gpio   \ Enable UART & All GPIO's          -           idem
    r> 2* 2*  2 over gpio!  \ UART on GPIO0/1 or GPIO4/5        IO-TX       IO-S?
    2  swap 1+ gpio!        \                                   -           IO-S?
    5A r> pads! ;           \ Set input+pullup for S?           -           -

\    decimal
\    24 25 b+b  15000  h+h  0 cfg ! \ 14 GPIO24 for S?, GPIO25 for led 
\                                   \ & clockfreq. in 10kHz steps
\    hx 40070000            1 cfg ! \ Default UART or 40078000
\    dm 115200              2 cfg ! \ Default baudrate
\    hx D0000004            3 cfg ! \ GPIO input address register
\    0                      4 cfg ! \ Load only noForth for core0 & start
extra: : CONFIG    ( -- )   \ Initialise system clock, etc.
    start-xosc              \ Start Xosc
    pll>  init-plls         \ Set PLL clocks = 240MHZ default
    init-clks               \ Set system clocks
    MAX-CLK cell+ cell+     \ To divider field
    c@+      48 clk-on      \ PERI clock = PLL_CLK/+n in MHz
    c@ dup   60 clk-on      \ USB clock  = PLL_CLK/+m = 48MHz
             6C clk-on      \ ADC clock  = PLL_CLK/+m = 48MHz
    restart-devices         \ Reset all RP2040
    false 40020000 !        \ Unreset all
    0C 2 ticks  0C 4 ticks  \ Start watchdog & Timer0 clocks for MS
    5AFE0206 40100088 !     \ Start always-on-timer on Xosc. & clear it
                            \ To read low32: 40100074 @ u.  High32: 40100070 @ u.
    set-gpio  set-uart      \ Activate UART & start Timer0 for MS
    0 cfg 2 + h@ 0A * khz   \ Set default system frequency
    &config catch ?abort ;  \ Add alternative configuration

extra: : SWITCH   ( -- )
    'key ['] tkey <> ?exit  \ Do nothing when not using built-in primitives
    state @ ?abort          \ Only for use while executing!
    1 cfg dup @  8000  2dup and
    0<> ?negate +  swap !  set-uart ;  immediate


\ 40064008 @ = 10000 = Reset pin
\            = 00100 = Reset brown-out, etc.
align,
label-AMSTERDAM                                         \ a(((
]   !S0
( ) main  begin @ dup main <>   \ All tasks except main asleep
( ) while  dup sleep repeat drop
    config  5 ms  led           \ Hardware configuration
    !created                    \ LFA of last header
{{+ fresh }}
    flybuf to fp                \ Init. fp
    fly}  tidy                  \ Check vectors
    s? if app catch !S0 then    \ start user application
    .logo  quit  [              \ show startup message

extra: code BOOT    ( -- )
    chere ivecs cell+ vec!  \ Install BOOT at second location in IVECS
    cpsid,                  \ Disable interrupts?
    pool,
      ivecs ,               \ W    = Interrupt table
      E000ED08 ,            \ HOP  = VTOR register
      tp> ,                 \ DAY  = Main TCB
      amsterdam ,           \ MOON = Address of high level BOOT part
    then,
    w { w hop day moon } ldm, \ 3 - Read all startup data
    w  hop ) str,           \ 2 - Set VTOR
    hop day his: r0 #) ldr, \ 2 - Read R0
    rp hop mov,             \ 1 - Set return stack to R0
    ip moon movs,           \ 1 - Set IP to noForth high level
    rotterdam 77 again,     \ 2+9 Restore DOES
end-code


(* Exception frame numbers are offset to RP (R13) from noForth & usage

| RPoff | Register  | Description 
|-------|-----------|--------------------------------------
| +0x00 | R0 = IP   | Argument / Result register 1 
| +0x04 | R1 = SP   | Argument / Result register 2 
| +0x08 | R2 = W    | Argument / Scratch register 3 
| +0x0C | R3 = TOS  | Argument / Scratch register 4 
| +0x10 | R12 = DOES| Intra-procedure-call scratch register 
| +0x14 | LR (R14)  | Link Register (Return Link) 
| +0x18 | PC (R15)  | Program Counter, the faulted/interrupted instruction
| +0x1C | xPSR      | Program Status Register, ALU flags and execution state
|-------|-----------|----------------------------------------

*)

\ Array that may hold PC, IP, TOS & RP at the moment a fault had occurred
inside: create FAULT-ADR  label-AMSTERDAM  -1 , -1 , -1 , -1 ,

\ Return from Hardfaults etc. to noForth
align,  label-ROTTERDAM
    ip pc mov,  ahead,      \ PC to IP to go execute high level message
       ]  !s0  cr cr  ." A hardfault occurred "
          E000ED28 @ u.  &fault execute  quit  [
    then,
    next,
align,  chere
    pool,  rotterdam ,  amsterdam ,  then, \ Code of hardfault handler
    w { hop day } ldm,      \ Read return addres & fault address pointer
    sun rp mov,             \ Copy R-stack pointer
    moon  sun 18 #) ldr,    \ Read previous PC
    hop  sun 18 #) str,     \ Replace PC pointer
    moon  day ) str,        \ Save erroneous PC, IP & TOS & RP
    ip  day 04 #) str,
    tos  day 08 #) str,
    sun 20 # adds,
    sun  day 0C #) str,
    lr bx,
dup  IVECS 2 cells +  vec! \ NMI vector
dup  IVECS 3 cells +  vec! \ HardFault vector
\ dup  IVECS 4 cells +  vec! \ Mem menage vector
\ dup  IVECS 5 cells +  vec! \ MPU BusFault vector
\ dup  IVECS 6 cells +  vec! \ MPU UsageFault vector
\ dup  IVECS 7 cells +  vec! \ MPU SecureFault vector
drop

\ For noForth we save the whole image in Flash and we reserve
\ space for two images of 0x80000 bytes each. Stored as:
\ The bootable file is stored in Flash from XIP address: 10000000
\
\ |  0 - 100  | 0100 to 81000 | to 101000 | 101000 to 400000
\ | Bootblock | Boot image-0  | image-1  | Free for NOF and/or LIB
\
\ So for NOF there is a space of: #1.568.768 bytes to #16.248.832 free.
\ Depending on the size of the Flash chips that ranges from 2 Mbyte to 16 Mbyte
extra: : FREEZE     ( -- )      frozen  ahead [ >box ] (;)
extra: : FREEZE2    ( -- )
    frozen2  [ box> ] then   here 100 + \ Image offset 0 or 1, adjust image
    dup FFF +  7F000 and >r             \ Save rounded image length
    10000000 over 100 move  {w          \ Copy secundairy boot, open Flash
    over r@ wipe-flash                  \ Erase old image
    over 0= if                          \ Write boot image?
        false over 100 write-flash      \ Yes, then write new secundairy boot
    then  drop   r@ ivecs !             \ Store rounded image length up front
    dup 0= 100 and +  ivecs             \ Get roma & rama
    r> write-flash  w} ;                \ Write image, close Flash

inside: code RESTART    ( a -- )  ( 38 bytes )
    401000B0 ,  \ W
    01FFFFF3 ,  \ HOP
    40018008 ,  \ DAY
    40100030 ,  \ SUN
    400D8000 ,  \ MOON
code>
    w  { w hop day sun moon } ldm,
    tos  w ) str,
    hop  day ) str,
    hop 1 # movs,
    hop sun ) str,
    hop 8 # movs,
    hop 1C # lsls,
    hop  moon ) str,
    next, \ begin, again,
end-code
extra: : COLD   ( -- )      false restart ;
extra: : COLD2  ( -- )      10081000 restart ;


forth: : EVALUATE   ( a n -- )
    @input ( ib #ib,>in@ source-id ) >r 2>r
    false h+h true ( ib #ib,>in@ source-id ) !input
    ['] interpret  catch
    2r> r> ( ib #ib,>in@ source-id ) !input  throw ;

forth: : '  ( <name> -- xt | ABORT )    bl-word find 0= ?abort ;
forth: : \  ( <tekst> -- )  #ib >in ! ;   IMMEDIATE
extra: : CH     ( <name> -- )   char  postpone literal ; IMMEDIATE
forth: : [CHAR] ( <name> -- )   postpone ch ; IMMEDIATE

{{+ forth: : WORDLIST      ( -- wid )
    wid-link     dup        \ top-link
    here to wid-link
    compile,                \ lnk,
    cell+ @ 1+ dup h,       \ new wid
    true h, ;  ( Pointer naar de naam van een vocabulary )
extra: : .VOC   ( voc# -- )
    wid-link
    begin ?dup 0= if ." voc#" . EXIT then
          2dup cell+        \ skip link
          h@ <>
    while compile@
    again then              \ voc# voc-cfa
    6 + dup h@
    FFFF over =
    if 2drop ." voc#" .
    else - 2 + count 1F and type space drop
    then ;
only: : ORDER         v0 vp - 9 1 within if fresh then
    (.)   space v0 vp
    begin  2dup > while  dup c@ .voc 1+ repeat
    drop ." : " c@ .voc ;                   \ .current
}}


\ --- conditionals ---
extra: : ?PAIR  ( x y -- )  - ?abort ;
forth: : THEN   ( a systhen -- )  11 ?pair here swap compile! ; IMMEDIATE
forth: : BEGIN  ( -- a sysbegin ) ?comp here 22 ; IMMEDIATE
forth: : WHILE  ( a x-id -- a systhen a x-id ) postpone if 2swap ; IMMEDIATE
forth: : ELSE   ( a systhen1 -- a systhen2 )
    postpone ahead 2swap postpone then ; IMMEDIATE
forth: : REPEAT ( a systhen a sysbegin -- )
    postpone again postpone then ; IMMEDIATE

inside: : DOER, , ;


\ ROUTINE starts the creation of a subroutine in assembler
extra: : ROUTINE   ( <name> -- syscode )
    create  false  55  {{+ assembler  }} ; \ Leave false & sec. code  

inside: : DOER!    ( -- )    r> created lfa> ! ;
extra: : NONAME ( -- xt syscode )       here  dup cell+ ,  true 55  {{+ assembler  }} ;
forth: : CODE ( <name> -- syscode )     HEADER  noname >r 2drop  false r> ;
assembler: : END-CODE ( syscode -- )    {{+ previous also  }}  55 ?pair  align  ?exit  reveal ;

assembler: : (DATA     ( -- s )     \ org = 6 cells, this = 18 cells
    here cell mod if 46C0 h, then   \ align,
    467A h,  here E000 h,  66 ;     \ w pc mov,  ahead,
assembler: : DATA)   ( s -- )
    align  66 ?pair                 \ (DATA used?
    >r  here r@ cell+ - 2/          \ Resolve ahead, ... then,
    r@ h@ or  r> h! ;

extra: : CODE>     ( s -- )         \ org = 14 cells, this = 25 cells
    dup 55 = ?abort  align          \ not valid in code definition!
    created lfa> dup @ < ?abort     \ cfa does not point forward?
    chere created lfa> !  false 55 {{+ assembler  }} ;
forth: : ;CODE   ( chere true 44 -- 55 )
    postpone [  44 ?pair  dup ?abort  postpone doer!  55 {{+ assembler  }} ; immediate

forth: : IMMEDIATE ( -- )     created  lfa>n dup c@ 80 or  swap c! ;
forth: : [']  ( <name> -- )   ' postpone literal ; IMMEDIATE


\ (* ... *) block comment, can be nested.
\ Both (* and *)  M U S T  be the first word on a line.
extra: : (*
    begin postpone \   bl-word count
        s" *)" 2over s<>
        over and
    while s" (*" s<> 0= if (* then      \ recursive
    repeat 2drop ; immediate

{{-  extra: : V:  postpone \ ; immediate  }}
{{+  extra: : V:  ; immediate  }}
{{+ inside: : -V: postpone \ ; immediate  }}
{{- inside: : -V: ; immediate  }}
extra: header C?   ' false @ doer, immediate
\ <><>

\ HERE  ...  {FLYBUF...TIB/}  ...  RAMBORDER
\ Move forth workspace {FLYBUF...TIB/} n bytes up
\ or down for negative n, do a reBOOT afterwards
extra: : GROW ( n -- )
    here flybuf -  max aligned  \ How much can i minimise
    ramborder tib/ -  min       \ How much can i maximise
    adr flybuf                  \ Do it on all pointers
    6 for  2dup +!  cell+  next
    drop  adr border +!  boot  (;)


\ ----- tell -----
tell CFG to-do:
    @  swap 4 umin cells + ; \ Secured data range

tell CREATE to-do:
    header doer, reveal ;
tell ?ABORT to-do:
    flyer compile,
    created lfa>n compile, ;
tell C"
tell S"
tell ." to-do:
    flyer
    compile,
    [char] " parse
    dup c, m,  align ;
tell LITERAL to-do:
    state @ if compile, , exit then drop ;
tell 2LITERAL to-do:
    state @ if compile, , , exit then drop ;
{{+ tell ONLY to-do:
    8 + >order drop ;       \ ( only only : only )
}}
tell SHIELD to-do:
    header doer, reveal
{{+ order, }}
    here 2 cells + compile, \ w+w
    uhere , ;
tell MARKER to-do:
    header doer, reveal
{{+ order, }}
    created ( lfa ) compile,      \ here
    uhere , ;
tell : to-do:
    header here S0 ! doer, false 44 ] ;    \ S0 for recurse
tell :NONAME to-do:
    align
    here S0 ! doer, S0 @ true 44 ] ;   \ true for no-reveal
tell CONSTANT to-do:
    header doer,  reveal , ;

tell VARIABLE to-do:
    header doer,  reveal  cell allot ; \ Standard version *WO*

tell VALUE to-do:
    header doer,  reveal , ; \ Now with init. value *WO*
\   drop  header ['] uvalue >body doer,  reveal , ; \ Now with init. value *WO*

tell UVALUE to-do:
    header  doer,
    reveal  uhere ,  uhere !  cell uallot ; \ Now with init. value *WO*
tell UVARIABLE to-do:                       \ Now also with defining part
    header doer,  reveal  uhere ,  cell uallot ;

{{+ tell VOCABULARY to-do:
    header doer, reveal wordlist drop
    here created lfa>n -
    here 2 - h! ;    \ points back to NFA, for .voc
}}
tell IF
tell AHEAD to-do:
    ?comp compile, here 11 true compile, ;
tell UNTIL
tell AGAIN to-do:
    swap 22 ?pair compile, compile, ;
tell DO
tell ?DO to-do:
    ?comp compile, here 33 true compile, ;
tell LOOP
tell +LOOP to-do:
    ?comp compile, 33 ?pair here swap compile! ;
tell FOR to-do:
    ?comp compile, here 333 true compile, ;

\ Next macro: ip { w } ldm,  w { hop } ldm,  pc hop mov,
extra: : NEXT,  ( -- )    C804 h,  CA10 h,  46A7 h, ;

tell NEXT to-do:
{{- state @ if }}
    ?comp  compile, 333
    ?pair dup cell+ compile,
    here swap compile!
{{- exit then  next, }}
    ;

\ -----
forth: : DOES> ( 0 44 -- -1 44 )
    state @ if 44 ?pair postpone doer!
    else align here [ ' doer! >body ] literal 2>r -1 ]
    then
    46E7B401 ,      \ Jump to DOES-intro is: { ip } push, pc does mov, (4)
    false S0 !  44 \ No recurse
    ; immediate

tell ; to-do:
    swap 44 ?pair compile, postpone [ ?EXIT reveal ;
    \ :noname has sys = true 44

tell POSTPONE to-do:
   ?comp
   bl-word find dup 0= ?abort
   0< if over compile, then compile, drop ;

extra: create BN   2 h, immediate
extra: create DM  0A h, immediate
extra: create HX  10 h, immediate
tell BN
tell DM
tell HX to-do:
    base @ >r   h@ base !  winterpret  r> base ! ;

tell to.u
tell +to.u
tell incr.u
tell adr.u

tell to.t
tell adr.t
tell his.t

to-do: ( rombody 'pfx ) compile,  @ , ;

\ ----- global prefixes
extra: create HIS   his# ,  immediate   \ 4
extra: create ADR   adr# ,  immediate   \ 3
extra: create INCR  incr# , immediate   \ 2
extra: create +TO   +to# ,  immediate   \ 1
forth: create TO    to# ,   immediate   \ 0
tell HIS
tell ADR
tell INCR
tell +TO
tell TO to-do:
    @ ' >r                  \ pfx# data-xt
    r@ @ +                  \ pfx-id
    pfx-link                \ pfx-id top-lfa
    begin dup 0= ?abort
        2dup cell+          \ skip link
        @ <>
    while lnk@          \ lnk@
    repeat
    nip                     \ lfa
    cell+ cell+ @           \ action ( xt-1 if imm )
    r> >body swap           \ rombody action
    dup aligned tuck =      \ rombody action even=not-imm?
    flyer
    if   compile,  ,        \ compile action and ramlocation *WO*
    else execute            \ execute action ( with rombody on stack )
    then ;
\ <><>


forth: shield NOFORTH\

( ) CHERE FF + 1FF00 and  MSTART !  \ Image length in front
( ) CHERE   ramadr: dp !
( ) UHERE   ramadr: uhere !
\ - - -
( ) CHERE  core !                       \ Set end of core
( ) DO-CHK  invert dup u.  core 4 + !   \ Store inverted checksum
( ) DO-CHK u.
( ) cr chere FF + 1FF00 and u.
( )    chere origin - u.
( ) CR CFG> U.  CFG> @  dup FF and . 10 rshift .

;;;NOFORTH;;;

( ) CHERE  to ROMHERE

\ make.hex
\ make.bin
cr .( Start UF2 conversion ) cr
  make.uf2

\ ----------------------------------------
