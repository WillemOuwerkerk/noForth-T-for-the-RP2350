\ noForth RP2040 -- metacompiler -- 10feb2023 noForth T runs
\ Copyright (C) 2020, Albert Nijhof & Willem Ouwerkerk

(*  noForth T metacompiler ( RP2040 )

     ----------------------------------------------
     This program is free software: you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation, either version 3 of the License, or
     (at your option) any later version.

     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.

     You should have received a copy of the GNU General Public License
     along with this program.  If not, see <http://www.gnu.org/licenses/>.
     ----------------------------------------------


  Header options:

\   | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 | 0 | 1
\   |      link     |voc|cnt| n | a | m | e | - | - |      cfa      | code
\
\ Links with 16-bit offset (possibly divided by 2). The effective maximum
\ distance between linked words then is 128 kByte, looks like enough:
\
\   | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 |
\   | link  |voc|cnt| n | a | m | e |      cfa      | code


  Memory map:

20000000 to IVECS       \ 48 vectors & default code
20000110 to IVECS/      \ Temporary gap for .T code
20000110 to HOT         \ Uhere starts here
20000200 to ORIGIN      \ HERE starts here
\ ... system ...
2003F800 to FLYBUF      \ 400 bytes
2003FC00 to FLYBUF/
2003FE80 to s0          \ 100 bytes
2003FF80 to r0          \ 200 bytes
2003FF80 to TIB         \ 100 bytes
20040000 to TIB/
20040000 to BORDER      \ Systems end
20080000 to RAMTOP      \ End of user RAM
20080000 to XRAM        \ Tasker RAM


There is no separate RAM for variables, the complete Forth is in RAM!!

*)

: (*    ( -- )
   0   \ dummy
   begin begin begin   drop
       ( cr ) refill 0= if exit then
       bl word
       count        2 = until
       count [char] * = until
       count [char] ) = until
   drop ; immediate

\ META I
only forth also definitions
marker -META
hex \ until the end

\ Primitive string set from P.F.W.
: C+!   ( n a -- )  >r  r@ c@ +  r> c! ;        \ Incr. byte with n at a
: $+!   ( c s -- )  >r  tuck  r@ count +  swap move  r> c+! ; \ Extend string 's' with 'c'
: $!    ( c s -- )  0 over c!  $+! ;            \ Store 'c' string into 's'

\ --- intro for win32forth ---
: 16!   w! ;
: 16@   w@ ;
: W!    abort" Wrong --- w! " ;
: W@    abort" Wrong --- w@ " ;

: .S
    ." ( " depth ?dup 0 >
    if begin dup pick .
        1- ?dup 0=
    until
    then ." ) " ;

: ?ERROR ( vlag cstring -- ) swap 0= if drop exit then
    count type ."  Error " .s -1 throw ;
: ?ABORT ( vlag -- ) last @ postpone literal
    postpone ?error ; immediate

\ Compiler noodstack, circulair, 8 elementen diep,
\ voor ongestructureerde nesting van conditionals.
: `CELLS ( n -- n*4 ) 2* 2* ;
: `CELL+ ( a -- a+4 ) 4 + ;
: @+ dup `cell+ swap @ ;
hex create box 48 allot
: >box ( x y -- )   1 box +!   box @+ 7 and 3 lshift + 2! ;
: box@ ( -- x y )   box @+ 7 and 3 lshift + 2@ ;
: box> ( -- x y )   box@   -1 box +! ;

\ ---
\ Error messages#hot-bytes
: ?PAIR ( x y - )   <> ?abort ;
: ?STACK    DEPTH 0< ?abort ;

: UPPER ( a32 n -- )
    over + swap
    ?do i c@ 61 7B within
        if  i c@ 20 - i c!
        then
    loop ;
: LOWER ( a32 n -- )
    over + swap
    ?do i c@ 41 5B within
        if  i c@ 20 + i c!
        then
    loop ;

\ Allot text as a counted string. See IGNORE `header x" `."
: STRING, ( a32 n -- )
    here swap c,   count   dup allot   move   align ;
: BL-WORD   ( -- countedstring32 )  \ Read next word, REFILL if necessary.
    begin bl word dup c@ if exit then
        drop refill 0= ?abort
    again ;
: doIGNORE      \ Ignore text until end-string is encountered.
    does>   count
    begin bl-word count 2dup upper 2over compare 0=
    until
    2drop ;
: IGNORE ( <start-string> <end-string> -- )
   create immediate doignore bl word count 2dup upper string, ;

IGNORE <---- ---->

<---- skips text until ---->

0 value vocs?

ignore +vocs }}
ignore -vocs }}

\ targ addresses
 0 value MSTART
 0 value HOT
 0 value HOT0
 0 value HOT1
 0 value IVECS
 0 value IVECS/
 0 value FLYBUF
 0 value FLYBUF/
 0 value S0
 0 value R0
 0 value TIB
 0 value TIB/
\ 0 value SYSBUF
\ 0 value SYSBUF/
 0 value ORIGIN
 0 value CHERE
 0 value UHERE
 0 value TOFFSET \ Tasker variable offset
 0 value BORDER
 0 value RAMTOP
 0 value XRAM    \ Tasker RAM
 8 constant DICT-THREADS \ 2, 4, 8 or hx 10 threads
   0 value IMAGE        \ start address of the image on the host
   0 value CREATED      \ LFA of the newest definition
   0 value CURRENTVOC   \ wid08
   0 value STATE?
   0 value TRACER       \ flag

vocabulary META
meta definitions also
: {{+ vocs?    ?exit postpone -vocs ; immediate
: {{- vocs? 0= ?exit postpone +vocs ; immediate
: }} ; immediate


\ 5 labels
0 value AMSTERDAM
0 value ROTTERDAM
0 value NOCATCHFRAME
0 value CORE
0 value TP>
0 value CFG>
0 value REFILL-VEC

: LABEL-AMSTERDAM       chere to amsterdam ;
: LABEL-ROTTERDAM       chere to rotterdam ;
: LABEL-NOCATCHFRAME    chere to nocatchframe ;
: LABEL-CORE            chere to core ;
: LABEL-TP              uhere to tp> ;
: LABEL-CFG             uhere to cfg> ;
: LABEL-REFILL-VEC      uhere to refill-vec ;

0 constant TO#
1 constant +TO#
2 constant INCR#
3 constant ADR#
4 constant HIS#
forth definitions
create BLOCK-BUFFER      1000 allot \ 4096 bytes UF2 block
here                     0100 allot \ Secundairy boot
here                    40000 allot \ 256 kByte UF2 file buffer
constant UF2-BUFFER
constant BINARY-BUFFER

: TARGANO?  ( adr -- err? )         20080000 2000000 within ;
: >HOSTA?   ( ta1 -- ha2 err? )     dup 20000000 -  image +  swap targano?  ;
: >TARGA?   ( ha1 -- ta2 err? )     image -  20000000 +  dup targano? ;

    include RP2040-DAS.f

only forth also definitions  \ -voc-

   0 value READY?       \ flag
   0 value WORDCOUNT    \ for compiler output format

\ Attention, imediately after the threads:
: (PFX-LINK)    hot dict-THReads `cells + ;   \ for TO etc.
: (WID-LINK)    hot dict-THReads 1+ `cells + ;  \ for WORD-list
\ - - -

\ <---- Intro ---->

<----  IMAGE
IMAGE is the address of 64k free space on the host.
In that space the image of noforth is built.
IMAGE is calculated automatically when meta-compiling starts,
see :::NOFORTH:::

IMAGE corresponds with virtual address 0 of the target

address types
>HOSTA converts a virtual Target address into the real Host address.
>TARGA converts a real Host address into the virtual Target address.
---->

\ Destructive MARKER
: ANEW ( <name> -- )    \ see :::noforth:::
    >in @ >r
    bl word find
    if  dup execute
    then
    drop   r> >in !   marker ;

: WIN   ( <word> -- ? ) bl-word count evaluate ;    \ winterpret

<----   Interim BASE and CH
while handling the next word in the input stream

: CH    \ same as [char] but also interactively
    char state @
    if postpone literal
    then ; immediate
---->

<---- select processor board ---->

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

create MYNAME   0 c, 30 allot align
create HEX-FILE 0 c, 30 allot align
create BIN-FILE 0 c, 30 allot align
create UF2-FILE 0 c, 30 allot align

: !MYNAME ( a u -- )
    myname place         \ v
    time&date [ decimal ] 100 mod
    3 0 do
    10 /mod [char] 0 + myname +ch     [ hex ]
            [char] 0 + myname +ch
    loop 2drop drop
( ) myname count hex-file place
    s" .hex" hex-file +text
    hex-file count lower    \ <----------
( ) cr uf2-file count type
    myname count bin-file place
    s" .bin" bin-file +text
    bin-file count lower    \ <----------
( ) myname count UF2-FILE place
    s" .uf2" UF2-FILE +text
    UF2-FILE count lower    \ <----------
    ;

: !NOF-NAME ( -- )      \ Default name
    vocs? if
        s" noForth tv# RP2350 solo "
    else
        s" noForth t# RP2350 solo "
    then  !myname ;

: vocskey
    cr ." Version with vocabularies?    + = yes   - = no   -> "
    key dup [char] + = to vocs?   emit cr  !nof-name ;

<---- tracing ---->

: WAIT/GO   ( -- )          \ for .chere TARGDUMP
    key? 0=   if exit then
    2 0 do key 1B = loop
    or ?abort ;          \ Stop on [ESC]

: .STACK    ( -- )          \ For .chere
    6 spaces .s ;
: ?"        ( "ccc" -- )
    postpone cr
    postpone ."
    postpone .s ; immediate

: RTYPE ( adr len r -- )    over max over - >r type r> spaces ;

\ Target needs alignment.

: TRACE     true to tracer ;
: NOTRACE   false to tracer ;
: .CHERE: state?   if exit then cr chere 0B .r 3 spaces ;
: `ALLOT ( n -- ) chere + to chere ;
: DOTW   ( x -- ) tracer if dup 0 <# # # # #s #> type space then ;
: DOTH   ( x -- ) tracer if dup 0 <# # # # # #>  type space then ;
: DOTB   ( x -- ) tracer if dup 0 <# # # #> type space then ;
: DOTW,  ( -- )   tracer if ." , " then ;
: DOTH,  ( -- )   tracer if ." h, " then ;
: DOTB,  ( -- )   tracer if ." c, " then ;
: DOTW!  ( -- )   tracer if ." ! " then ;
: DOTH!  ( -- )   tracer if ." h! " then ;
: DOTC!  ( -- )   tracer if ." c! " then ;

\ little endian supposed for host and target
: W,    ( x -- )        dotw chere >hosta? ?abort  !  4 `allot dotw, ;
: H,    ( x -- )        doth chere >hosta? ?abort 16! 2 `allot doth, ;
: B,    ( x -- )        dotb chere >hosta? ?abort c!  1 `allot dotb, ;
: MC,   ( +n -- )       0 ?do  FF b,  loop ;

: W!    ( x `a -- )     swap dotw swap dotw >hosta? ?abort   ! dotw! ;
: H!    ( x `a -- )     swap doth swap dotw >hosta? ?abort 16! doth! ;
: B!    ( ch `a -- )    swap dotb swap dotw >hosta? ?abort  c! dotc! ;

: W@    ( `a -- n )     >hosta? ?abort @ ;      \ 32-bit @
: H@    ( `a -- n )     >hosta? ?abort 16@ ;    \ 16-bit @
: B@    ( `a -- n )     >hosta? ?abort c@ ;     \  8-bit @

: IMAGE-DEF     ( -- )
    FFFFDED3  w,             \ Magic header number
    10210142  w,             \ Arm secure mode
    000001FF  w,             \ Block is one word long
    00000000  w,             \ Only a single block
    AB123579  w, ;           \ Magic footer number

: PREP-BLOCK    ( -- )      \ Correct for all RP2350 vectors
    image 1000 0 fill           \ First erase whole buffer
    20080000 w,                 \ Add highest RAM address
    43 0 do 10000111 w, loop ;  \ First UF2 block are interrupt vectors
                                \ All jumps to 10000110

04C11DB7 constant crc-polynomial ( Original: J.J. Hoekstra )
: CRC        ( a2 a1 -- crc )           \ input is address and length
    FFFFFFFF -rot                       \ FFFFFFFF = start-value CRC
    ?do
        i c@ 18 lshift xor
        8 0 do
            dup 1 lshift  swap          \ Duplicate & left shifted result
            0< crc-polynomial and  xor  \ Add polynomial
        loop
    loop ;

: MAKE-CRC  ( -- )
    image FC +  dup image CRC  swap !
    chere FF +  FFFFFF00 and  to chere ;

: .NAME ( a32 -- )  tracer if count 8 rtype space exit then drop ;
: .STRING   ( a n -- )
    tracer
    if  .chere: dup dotb [char] " emit
        type [char] " emit 2 spaces exit
    then 2drop ;

: .CHERE ( -- )
    tracer
    if  .stack cr chere .
        state? if 3 spaces then
    then
    wait/go ;
: .UHERE  ( -- ) tracer if  ."  UHERE " UHERE . then ;

: STOP?     ( - true/false )
    key? dup 0= ?exit
    drop
    key  bl over =   if drop key then   \ key
    01B over =   ?abort
    bl <> ;

<---- `words
  are words that do not behave the same way in noforth as in the host-forth.
  these words operate on virtual targ addresses!
---->

: `ALIGN    ( -- )  chere 1 and if  0FF b, then
                    chere 2 and if FFFF h, then ;
: DOTM,   ( a n -- )
    tracer
    if  [char] " emit type
        [char] " emit ."  m,  " exit
    then 2drop ;
: `M,   ( a n -- )          2dup dotm, chere >hosta? ?abort swap dup `allot move ;
: `STRING,  ( a32 n -- )    dup b, `m, ; \ Allot as counted string, needs ALIGN


\ header
: (>BODY)   4 + ;
: (LFA>N)   5 + ;
: `LNK@     ( lfa.t -- lfa2.t )     w@ ;
:  `LFA>    ( lfa.t -- cfa.t )
    >hosta? ?abort
    (lfa>n) count 1F and +
    3 + -4 and   >targa? ?abort ;
: `@IMM     ( lfa.t -- 1/-1 )
    (lfa>n) b@ 80 and 0= if -1 else 1 then ; \ 31jan2023

vocabulary MASM        \ aux words for meta-assembler
: MASM:     masm definitions ;
: META:     meta definitions ;

only forth also definitions   \  -voc-
masm also
meta also

include noForth-T-asm-M33.f

hex only forth also meta also  forth definitions
: 'VEC!     ( a v -- )    >r 1 or r> w! ; \ Build an ARM corrected jump to 'a' at address 'v'

meta:

<---- END OF META1 ---->
\ safety numbers
11 constant SYS-IF      \ for then ahead while
22 constant SYS-BEGIN   \ for until again
33 constant SYS-DO      \ for ?do loop +loop
44 constant SYS-COLON   \ for : ; does> ;code
55 constant SYS-CODE    \ for end-code ;code does>
\  See Assembler
\ 66 constant SYS-IF,    \ for then, ahead, repeat,
\ 77 constant SYS-BEGIN, \ for until, again, repeat,
\ 88 constant SYS-COND   \ Conditionals
\ -----------------------------  meta II -------------------------

<---- META II - an - 19mei04 ---->

forth definitions
hex

create WORDA    22 allot align      \ the result of BL WORD is stored there
: >WORDA    ( a n -- )
    1F over < ?abort
    dup worda c! worda 1+ swap move ;
: THREAD#   ( bl-word -- nr )
    count swap c@ xor dict-THReads 1- and ;
: THREAD    ( bl-word -- targa )
    thread# `cells hot +  ;             \ dictionary
: S<> ( a n a n -- <>? )    \ worda nfa-1 <>?
    rot over <> if nip 2drop true exit then
    0 ?do over c@ over c@ <>
        if 2drop true unloop exit
        then 1 1 d+
    loop 2drop false ;

\ V-version
: `FIND-NAME ( worda lfa.t -- worda 0 | cfa.t imm )
    begin
        dup 0= ?exit            ( worda lfa.t )    \ end of list?
        2dup  (lfa>n) >hosta? ?abort     ( worda lfa.t worda nfa.h )
        >r count r> count
        1F and s<>       \ unequal?
    while
        `LNK@                   ( worda lfa.t )
    repeat                      ( worda lfa-yes )
    nip dup  `lfa>              ( lfa.t cfa.t )
    swap `@imm ;                ( cfa.t imm )

: `FIND ( worda  -- worda 0 | cfa.t imm )
    dup count upper
    dup thread                  \ contains topword lfa.t
    w@                          \ worda toplfa.t
    `find-name ;
: LNK,  ( link-holder-targa -- )
    chere   over w@ w,   swap w! ;

: `HEADER       \ builds header WITHOUT codefield
    depth if cr .stack then
    tracer
    if ( cr cr )
    else wordcount 0a mod 0= if cr then
    then
    1 wordcount + to wordcount
    .chere bl-word count >worda
    worda
    `find
    nip
    if  cr ." --- redefining:"
    then
    tracer   if ." <<<<< " then
    space worda count type space
    tracer   if ."  >>>>> " .chere: then    \ print name
    `align
    chere to CREATED
    worda thread lnk,
    .chere tracer   if 0A spaces then
\ hvoc
    currentvoc 80 or b,                     \ hvoc
\ count+name
    worda count dup b, `m,
    `align
\ ) chere 2 and if FFFF h, then             \ kkk *WO*
    ;            \ icount & name

\ ----- i n t e r p r e t -----
: `COMPILE, ( a.t - )   w, ;

: NAME: ( <name> -- )
    bl-word count >worda worda count postpone sliteral ;
: FIND-IT   ( a n -- xt16 )
    >worda worda .name worda `find ?exit   ?abort ;

: TOKEN:    ( a n -- xt )   name: postpone find-it ; immediate

: `LITERAL  ( x -- ? ) state? 0= ?exit token: literal  (>body) `compile, w, ;
: `2LITERAL ( dn -- ) state? 0= ?exit token: 2literal (>body) `compile, w, w, ;

: DOER,  ( doeradr -- )     w, ;
: DOER!  ( doeradr a -- )   w! ;
: `CREATE `header token: CREATE (>body) doer, ; \ ^^^

<----  Late binding (avoiding forward refences)
NAME: ccc compiles ccc as a string in the meta-compiler.
At target compile time
   TOKEN: ccc
             search for ccc in image.
---->

meta definitions
get-current         cr .stack .( get-current )

forth definitions
constant META-WID   cr .stack

: IN-META?  ( worda -- xt imm? -- 0 )   count meta-wid search-wordlist ;

\ --------------------------------------

\ Converting a string into a  SINGLE number, the minus sign is accepted.
: -SIGN?    ( a n -- a n false | a+1 n-1 true )
    dup
    if  over c@ [char] - =
        if  1 /string true exit
        then
        false
    then ;
: NUM?  ( blword -- xlo err? )  \ Counted string --> -single number
    count -sign? >r
    dup
    if  false dup 2swap >number 0= nip nip
    then            \ xlo t/f
    r>
    if  swap negate swap
    then 0= ;

: NN
<----
state?                 \ qqq
    if  bl-word num? ?abort
        bl-word num? ?abort
        token: 2literal (>body) `compile,
        w, w,
    then
---->
    ;

: WINTERPRET    ( bl-word -- )
    count >worda                            \ result in worda
    worda .name
    state?
    if  worda `find
        0<   if `compile, exit then         \ Compile when not immediate
        drop                                \ Immediate or NOT found
    then
    worda in-meta? ?dup if state? = ?abort execute exit then
    worda num? ?abort `literal ;                   \ Number? -> compile if necessary

: METACOMPILING         ( -- )
    begin
        .chere
        bl-word winterpret
        ready?
    until
    ready? 1- to ready?
    ready?   if  ."  R e a d y "  then ;

<---- metacompiler start / stop ---->
: `UALLOT ( n -- )    .UHERE  uhere + to uhere ;
\ : ?? ( a n -- ) cr 2dup evaluate 8 .r space type ;
meta
: :::NOFORTH::: ( -- )      \ start meta compiling
    forth
    0 to wordcount
    0 to ready?
    0 to state?
    s" anew -noforth" evaluate              \ Destructieve marker
    here -10000 and 40000 + to image
    image 10000 ff fill
    cr myname count type
    hot to UHERE
    0 to TOFFSET
    hot >hosta? ?abort 200 0 fill
    origin to chere
cr ivecs   9 u.r space ." IVECS"
cr hot     9 u.r space ." hot "
cr uhere   9 u.r space ." uHERE"
cr toffset 9 u.r space ." Toffset"
cr origin  9 u.r space ." ORIGIN"
cr chere   9 u.r space ." chere"

cr flybuf  9 u.r space ." FLYBUF"
cr flybuf/ 9 u.r space ." FLYBUF/"
cr s0      9 u.r space ." S0"
cr r0      9 u.r space ." R0"
cr tib     9 u.r space ." TIB"
cr tib/    9 u.r space ." TIB/"
cr dict-threads 9 u.r space ." DICT-THREADS"
cr image   9 u.r space ." IMAGE"
    cr cr ." type . if you want to continue "
    [char] . key <> ?abort             \ continue?
    cr
        ." We gaan! " cr
    METACOMPILING ;
forth

: MYNAME,   myname count dup b, `m,   `align ;
: MYNAME2,  s" M33 core with ARMv8-M ISA" dup b, `m, `align ;

\ METACOMPILING will stop when READY? has become True (in ;;;NOFORTH;;;)

: ;;;NOFORTH;;; ( -- )      \ finish meta compiling
    true to ready?
cr ." origin chere "  origin . chere .
cr ." hot uhere " hot .  uhere .
cr ." tp : " tp> .  toffset .
cr ." hehe    "
;

<----
 :::NOFORTH:::   start meta compiling
 ;;;NOFORTH;;;   finish meta compiling
 ( first and last commando of the Target compiler code )
---->

CR  .(   END of META II )

\ -----------------------------  meta III -------------------------
\ Meta III - an - 19mei04

<---- d e f i n i n i n g  w o r d s ---->

forth definitions also meta

: `IMMEDIATE    CREATED (lfa>n)  dup b@ 80 or  swap b! ;    \ 05feb2023
: `[    0 to state?  ;
: `]    -1 to state?  ;
: `:    ( <name> -- )   `header token: : (>body) doer, sys-colon 0 `] ;
: `:noname ( -- sys-colon )     token: : (>body) doer, sys-colon 0 `] ;
: `;    ( -- ) token: ; (>body) `compile, + sys-colon ?pair  `[ ;


(* Adding Forth style literal pool
: ALIGN,    ( -- )              here cell mod 0= ?exit noop, ; \ Cell align opcode
: DATA>     ( s1 -- s1 s2 )
    align,  w pc mov,  ahead, ;     \ Add start of loose literal pool   a1 55 a2 66
: CODE>     ( s -- s )
    halign                          \ Half word align
    dup 66 = if  then,  exit  then  \ DATA> (s2) used?
    over here  swap ! ;             \ End pool start code
*)


\  Normal version
: `END-CODE     sys-code ?pair  drop  `align ;
\ : DATA>         align,  w pc mov,  ahead, ;
: `CODE>        dup sys-code ?pair  `align  chere  created `lfa>  w! ;
: NONAME     ( -- sys-code ) chere (>body) doer,  chere sys-code ;
: `CODE      ( <name> -- sys-code )  `header NONAME ;
: `ROUTINE   ( <name> -- sys-code )  `create  chere sys-code ;
: `VARIABLE  ( <name> -- )   `header token: VARIABLE (>body) doer,  4 `allot ;
: `VALUE     ( <name> -- )
    `header token: UVALUE (>body) doer,
    chere w,  chere `cell+ w!  4 `allot ;
: `UVARIABLE ( <name> -- )
    `header token: UVARIABLE (>body) doer,  UHERE w,  4 `uallot ;
: `UVALUE    ( x <name> -- )
    `header token: UVALUE (>body) doer,
    UHERE w,  uhere w!  4 `uallot ; \ geinitialiseerd

: `TALLOT    ( n -- )   dup +to toffset  `uallot ;
: `TVARIABLE ( x <name> -- )
    `header token: TVAR (>body) doer,
    toffset w,  uhere w!  4 `tallot ;
: `TVALUE    ( x <name> -- )
    `header token: TVAL (>body) doer,
    toffset w,  uhere w!  4 `tallot ;
: `CONSTANT  ( n <name> -- ) `header token: CONSTANT (>body) doer, w, ;
\ : `PREFIX    ( pfx# <name> -- )  `header token: `PREFIX (>body) doer, w, `immediate ;

: `'        ( <name> -- cfa-targ )
    bl-word dup .name `find 0= ?abort ;
: TELL      ( <name> -- )   `align  chere `' doer! ;   \ store doer in cfa of <name>
: TO-DO     ( -- sys-code ) sys-code ;
: TO-DO:    ( -- sys-colon 0 ) \ >forth
    46E7B401 w,        \ Jump to DOES-intro is: { ip } push, pc does mov,
    `] sys-colon 0 ;
\ Define a doer for <name> and put its address in CFA of <name>
\ TELL <name> TO-DO: ...hilevel-code... ;

: `RECURSE  ( -- )  CREATED  `lfa> `compile, ;

: ONLY:         0 to currentvoc ;
: FORTH:        1 to currentvoc ;
: INSIDE:       2 to currentvoc ;
: EXTRA:        3 to currentvoc ;
: ASSEMBLER:    4 to currentvoc ;

<---- [430] \ v
 The numbers 0,1,2,...7C are 'wid's
---->

\ ---- a n d e r e  r o d e  w o o r d e n ----
: `POSTPONE    ( <name> -- )
    bl-word dup .name
    `find dup 0= ?abort
    0<   if token: postpone (>body)  `compile,  then
    `compile, ;

: `S" ( <ccc"> -- ) token: s" (>body) `compile, [char] " parse `string, `align ;
: `." ( <ccc"> -- ) token: ." (>body) `compile, [char] " parse `string, `align ;

: LASTNAME  ( -- a )    CREATED  (lfa>n) ;
: `?ABORT    token: ?ABORT (>body) `compile, LASTNAME w, ;

: `CHAR ( -- ch )
    bl-word dup .name
    count 0= ?abort
    c@ ;

: `[CHAR]   ( <ccc> -- ch | )
    `CHAR `literal ;
: `[']  ( <name> -- )   `' `literal  ;

\ V-version
: PFX-FOR-UVALUE ( pfx# <name> -- sys-code ) \ define local pfx
    (PFX-LINK) lnk,
    token: UVALUE (>body) + w,       \ pfx-id
    bl-word dup .name `find
    dup 0= ?abort
    1 = if 1- then
    w, ;

: PFX-FOR-TVALUE ( pfx# <name> -- sys-code ) \ define local pfx
    (PFX-LINK) lnk,
    token: TVAL (>body) + w,       \ pfx-id
    bl-word dup .name `find  dup .
    dup 0= ?abort
    1 = if 1- then
    w, ;

: PFX-FOR-TVARIABLE ( pfx# <name> -- sys-code ) \ define local pfx
    (PFX-LINK) lnk,
    token: TVAR (>body) + w,       \ pfx-id
    bl-word dup .name `find  dup .
    dup 0= ?abort
    1 = if 1- then
    w, ;

: PFX-FOR-VALUE ( pfx# <name> -- sys-code ) \ define local pfx
    (PFX-LINK) lnk,
    token: VALUE (>body) + w,       \ pfx-id
    bl-word dup .name `find
    dup 0= ?abort
    1 = if 1- then
    w, ;

\ compile `PREFIXed values, for ex. TO LISA
: PFXOBJECT,    ( pfx# <ccc> -- data-xt doval ) \ test op DOVAL
    `'   tuck w@                \ 'LISA to# doval?
    token: UVALUE (>body)       \ 'LISA to# doval? doval
    over <> >r \ ?abort         \ LISA is not a uvalue
\   Add TVAR pfx check
    token: TVAR (>body)
    over <> >r
    token: TVAL (>body)         \ LISA not a TVALUE
    over <> r> and  r> and ?abort
    +  (PFX-LINK)               \ 'LISA pfx-id (pfx-link)
    w@                          \ 'LISA pfx-id top-lfa
    ahead
    begin `LNK@                 \ 'LISA pfx-id lfa?
        [ 1 cs-roll ]
    then
        dup 0= ?abort           \ 'LISA pfx-id lfa
        2dup 4 +
        w@
        =                       \ 'LISA pfx-id lfa \ pfx-id correct?
    until nip                   \ 'LISA lfa
    cell+ cell+ w@ dup 1 and if \ pfx is imm?
        1+ ( aligned )          \ Align CFA
        (>body) `compile,       \ Action
        (>body) w@ w,           \ RAM address pointer
    else `compile, (>body) w,   \ Action & inline RAM address
    then ;

: `TO
        state? if
        to#   pfxobject,        ( 0 <ccc> -- )
        else true `?abort then ;
\       else ' >body ! then ;
: `+TO  +to#  pfxobject, ;      ( 1 <ccc> -- )
: `INCR incr# pfxobject, ;      ( 2 <ccc> -- )
: `ADR  adr#  pfxobject, ;      ( 3 <ccc> -- )
: `HIS  his#  pfxobject, ;      ( 4 <ccc> -- )
: RAMADR:   ( <name> -- ramadr ) `' (>body) w@ ;
: HIS:      ( <name> -- offset ) ramadr: ;
\ V-version
: `VOCABULARY ( wid -- )
    `header
    dup 0= if  0 (WID-LINK) w! then     \ init
    token: VOCABULARY (>body) doer,
    (WID-LINK) lnk,
    dup h,                          \ wid
    chere 2 + CREATED (lfa>n) - h,  \ offset to nfa voor .voc
    0=                              \ only?
    if  3 b, 0 b, 0 b, 0 b,         \ only's order
    then ;

\ -----  immediate compiler words -----
: `IF       ( -- IFa sys-if ) token: IF (>body) `compile,
    chere -1 w,  sys-if ;
: `AHEAD    ( -- AHEADa sys-if )  token: AHEAD (>body) `compile,
    chere -1 w,  sys-if ;

: `THEN     ( IFa sys-if -- ) sys-if ?pair chere swap w! ;
: `/THEN    ( IFa sys-if x y -- )   2swap `THEN ;

: `BEGIN    ( -- BEGINa sys-begin ) chere sys-begin ;
: `UNTIL    ( a sys-begin -- ) sys-begin ?pair
    token: UNTIL (>body) `compile, w, ;
: `AGAIN    ( a sys-begin -- ) sys-begin ?pair
    token: AGAIN (>body) `compile, w, ;

: `ELSE ( IFa sys-if -- AHEADa sys-if )     `AHEAD `/THEN ;
: `WHILE    ( x n -- IFa sys-if x n )       `IF 2swap ;
: `REPEAT   ( WHILEa sys-if BEGINa sys-begin -- )   `AGAIN `THEN ;
: `GOTO     ( BEGINa -- )   sys-begin `AGAIN ;      \ for labels

\ Formal end of colon definition, without compiling EXIT
: (;)   ( sys-colon -- )    drop sys-colon ?pair  ( reveal )  `[ ;

\ ----- DO LOOP - nov2019
\ DO..LOOP
: `DO   ( -- adr sys-do )   token: DO (>body) `compile,
    chere -1 w, sys-do ;
: `?DO  ( -- adr sys-do )   token: ?DO (>body) `compile,
    chere -1 w, sys-do ;
: `LOOP ( DOadr sys-do -- ) token: LOOP (>body) `compile,
    sys-do ?pair chere SWAP w! ;
: `+LOOP    ( DOadr sys-do -- ) token: +LOOP (>body) `compile,
    sys-do ?pair chere SWAP w! ;

: `FOR  ( -- adr 333 )   token: FOR (>body) `compile,
    chere -1 w, 333 ;
: `NEXT ( FORadr sys -- )
    state?
    if  token: NEXT (>body) `compile,  333 ?pair
        dup cell+ w, chere SWAP w!
    else  next,  then ;

0 value ROMHERE
: DO-CHK    ( -- checksum )
    cr ." Checksum "  -1 ( start value )
    chere dup .  >hosta? ?abort
    origin dup .  >hosta? ?abort
    ?do  i @ xor  4 +loop ;  \ checksum

\ V-version
: SHIELD    ( <name> -- )
    `header token: shield (>body) doer,
vocs? if
        chere token: FRESH (>body) 4 +  \ literal in FRESH
        dup w@ FFFFFFFF =
        if  w!              \ patch in FRESH, adr van zoekstack
        else true abort"  error in noForth shield "
        then
        5 b, 1 b, 1 b, 3 b, 0 b, 1 b,   \ forth forth extra only : forth
        FF b, FF b,     \ 32align
    then
    chere 2 `cells + w,
    UHERE w, ;                  \ !!!
\ - - -

\ ============= herdefinities in META ==================

: DOMETA: does> @ execute ;

: META-WORDS:       \ List, on every line: new (META) name & FORTH name
    begin
        refill 0= ?abort    \ ***
        create dometa:
        '
        here over `cell+ = ?abort
        dup ,
        [char] m parse 1- + c@ [char] i = if immediate then
        ['] ;;;noforth;;; =
    until
     ;

<----
 Wil je iets veranderen?
 LET OP:
 Begin op iedere regel met een META-naam en een FORTH-woord,
 de rest van de regel wordt niet gelezen.
 Geen lege regels!.
 De laatste META-naam moet ;;;NOFORTH;;; zijn.

 You want to change something in this list?
 ATTENTION:
 Start every line with the META name followed by the already defined FORTH word.
 The rest of the line will be ignored.
 No empty lines!
 The last META name in the list must be ;;;NOFORTH;;;

 WHEN META-COMPILING:
 Only meta-words can be found and executed.
 Only words that already extist in the target can be found and compiled.
---->

: TDUMP ( adres len -- )
    >r >hosta? ?abort r> cr dump ;

: `MOVE ( a1 a2 n -- )
    >r >r >hosta? ?abort
    r> >hosta? ?abort
    r> move ;

: `FILL ( a1 u b -- )
    2>r  >hosta? ?abort  2r> fill ;

: DAS   ( 'naam' -- )   `'  >hosta? ?abort  mdas) ;
: MDAS  ( adr -- )      >hosta? ?abort  mdas) ;



: LIST  ( +n -- )
    7 and 4 * hot +  >hosta? ?abort  @
    begin  ( dup .hex  )?dup while
        dup (lfa>n) >hosta? ?abort
        count 7F and type space space
        >hosta? ?abort  @
    key? until  then ;

: MWORDS    ( -- )
    8 0 do  cr i . i list cr  loop ;


\ Decompile literals, jumps & strings
: (MSEE)    ( ha1 ha@ -- ha2 )
    dup >targa? ?abort >r               \ ha ha@
    token: LITERAL (>body) r@ =         \ ha ha@ f
    token: IF (>body) r@ = or           \ ha ha@ f
    token: UNTIL (>body) r@ = or        \ ha ha@ f
    token: AHEAD (>body) r@ = or        \ ha ha@ f
    token: DO (>body) r@ = or           \ ha ha@ f
    token: ?DO (>body) r@ = or          \ ha ha@ f
    token: FOR (>body) r@ = or          \ ha ha@ f
    token: NEXT (>body) r@ = or         \ ha ha@ f
    if  r> 2drop  4 +  dup @ .hex  exit  then \ ha+4
    token: ." (>body) r@ =              \ ha ha@
    token: S" (>body) r@ = or
    if  r> 2drop  4 + count 2dup type   \ ha+$
        + 1- -4 and  exit
    then
    token: 2LITERAL (>body) r@ =        \ ha ha@
    if  r> 2drop  4 + 2@ d.  4 +  exit  \ ha+8
    then
    r> 2drop  ;

: MSEE      ( "name" -- )
    `'  dup .hex                        \                                   ta
    begin
        cr  4 + dup .hex                \ Print targa                       ta+
        >hosta? ?abort                  \ Convert to hosta                  ha
        dup @ dup .hex  >hosta? ?abort  \ Fetch contents & convert to hosta ha ha@
        dup 4 - begin                   \                                   ha ha@ ha@
            begin 1- dup c@ FF <> until \                                   ha ha@ hna?
        dup c@ 80 and until  1+
        count 1F and type space         \                                   ha ha@
        (MSEE)  >targa? ?abort          \                                   ta
    key bl <> until  drop ;


ONLY FORTH ALSO
META DEFINITIONS FORTH  \ -voc-
\ meta-name     forth-name   (Redefine all these Forth words in META)

META-WORDS:
    -               -
    ,               w,
    ;               `;      imm
    :               `:
    :NONAME         `:noname
    !               w!
    ?ABORT          `?abort imm
    ?DO             `?do    imm
    .               .
    ."              `."     imm
    .STACK          .s
    '               `'
    (               (       imm
    (*              (*      imm
    (;)             (;)     imm
    [               `[      imm
    [']             `[']    imm
    [CHAR]          `[char] imm
    [ELSE]          [else]  imm
    [IF]            [if]    imm
    [THEN]          [then]  imm
    ]               `]
    @               w@
    /THEN           `/then  imm
    \               \       imm
    COMPILE,       `compile,
    +               +
    +LOOP           `+loop  imm
    +TO             `+to    imm
    <----           <----   imm
    >BODY           (>body)
    0=              0=
    1-              1-
    2*              2*
    2DUP            2dup
    2LITERAL        `2literal imm
    2ROT            2rot
    2SWAP           2swap
    ADR             `adr    imm
    AGAIN           `again  imm
    AHEAD           `ahead  imm
    ALIGN           `align
    AND             and
    ASSEMBLER:      assembler:
    B+B             b+b
    BEGIN           `begin  imm
    BORDER          border
    >BOX            >box
    BOX>            box>
    BOX@            box@
    C,              b,
    C!              b!
    CELL+           `cell+
    CELLS           `cells
    CHAR            `char
    CHERE           chere
    CODE            `code
    CODE>           `code>
    CONSTANT        `constant
    CR              cr
    CREATE          `create
    DECIMAL         decimal
    DICT-THREADS    dict-threads
    DO              `do     imm
    DO-CHK          do-chk
    DOER,           doer,
    DROP            drop
    DUP             dup
    ELSE            `else   imm
    END-CODE        `end-code
    EXTRA:          extra:
    FILL            `fill
    FOR             `for    imm
    FORTH:          forth:
    FLYBUF          flybuf
    FLYBUF/         flybuf/
    GOTO            `goto
    H+H             h+h
    H,              h,
    H!              h!
    H@              h@
    HIS             `his    imm
    HIS:            his:
    HEADER          `header
    HEX             hex
    HOT             hot
    IF              `if     imm
    IMAGE-DEF       image-def
    IMMEDIATE       `immediate
    INCR            `incr   imm
    INSIDE:         inside:
    INVERT          invert
    IVECS           ivecs
    LASTNAME        lastname
    LITERAL         `literal    imm
    LOOP            `loop   imm
    MAKE-CRC        make-crc
    MC,             mc,
    MOVE            `move
    MSTART          mstart
    MYNAME,         myname,
    MYNAME2,        myname2,
    NEXT            `next   imm
    NN              nn      imm
    NONAME          noname
    NOTRACE         notrace
    ONLY:           only:
    OR              or
    ORDER:          order
    ORIGIN          origin
    OVER            over
    PFX-FOR-TVALUE  pfx-for-tvalue
    PFX-FOR-TVAR    pfx-for-tvariable
    PFX-FOR-UVALUE  pfx-for-uvalue
    PFX-FOR-VALUE   pfx-for-value
    POSTPONE        `postpone   imm
    prep-block      prep-block
    RAMADR:         ramadr:
    RAMTOP          ramtop
    RECURSE         `recurse    imm
    REPEAT          `repeat imm
    ROMALLOT        `allot
    ROMHERE         romhere
    ROT             rot
    ROUTINE         `routine
    R0              r0
    RSHIFT          rshift
    S"              `s"     imm
    SHIELD          shield
    S0              s0
    SWAP            swap
    TALLOT          `tallot
    TDUMP           tdump
    TELL            tell
    THEN            `then   imm
    TIB             tib
    TIB/            tib/
    TO              `to     imm
    TO-DO           to-do
    TO-DO:          to-do:
    TRACE           trace
    TVALUE          `tvalue
    TVARIABLE       `tvariable
    U.              u.
    UALLOT          `uallot
    UHERE           uhere
    UVARIABLE       `uvariable
    UNTIL           `until  imm
    UVALUE          `uvalue
    VALUE           `value
    VARIABLE        `variable
    VEC!            'vec!
    VOCABULARY      `vocabulary
    WHILE           `while  imm
    XRAM            xram
    ;;;NOFORTH;;;   ;;;noforth;;;

\ ;;;NOFORTH;;; MUST be the last item in the list.

trace
only forth also definitions
<----
20000000        to MSTART  \ Start of binary
mstart 00000 +  to IVECS   \ 48 vectors & default code
mstart 00110 +  to IVECS/  \ Temporary gap for .T code
mstart 00110 +  to HOT     \ Uhere starts here
mstart 00200 +  to ORIGIN  \ HERE starts here
\ ... system ...
mstart 1F800 +  to FLYBUF  \ 400 bytes
mstart 1FC00 +  to FLYBUF/
mstart 1FD00 +  to S0      \ 100 bytes
mstart 1FF00 +  to R0      \ 200 bytes
mstart 1FF00 +  to TIB     \ 100 bytes
mstart 20000 +  to TIB/
mstart 20000 +  to BORDER  \ Systems end
border          to RAMTOP  \ End of user RAM for image-0

cr cr  .(                    de metacompiler is geladen )
cr cr
---->

hex
\ 0 value ROMHERE
0 value CHK
20 value B/LINE
0 value FILEID
: SLUIT fileid close-file cr ." close-file " . ;
: ZEND  ( a n -- )  fileid write-file drop ;
: .XX   ( n -- )    dup chk + to chk  0 <# # # #> zend ;
: .XXXX ( n -- )    dup 8 rshift .xx .xx ;
create NEWLINE  hex 0D c, 0A c, align
: INTELHEX  ( begina count -- ) \ >hosta? ?abort
    cr .s
    over + swap                 \ enda begina
    begin
        2dup - b/line umin      \ enda begina len
        dup                     \ #bytes
    while                       \ 1 line
        s" :" zend  0 to chk    \ record mark
        dup .xx                 \ reclen
        over .xxxx              \ load offset \ address
        0 .xx                   \ rectyp
        0 do count .xx loop     \ data
        chk negate .xx          \ chksum
        newline 2 zend
    repeat
    drop 2drop ;


: MAKE.HEX ( -- )       \ make noforth.hex file
    hex-file count
    cr 2dup type
    w/o create-file throw
    to fileid
    s" :020000040800F2" zend
    cr
    MSTART  >hosta? ?abort
    romhere >hosta? ?abort
        over - intelhex
    s" :00000001FF" zend
    newline 2 zend
    fileid close-file throw
    cr hex-file count type ." done " ;


: MAKE.BIN          \ Make noforth binary file
    bin-file count
    w/o bin create-file throw
    to fileid
    MSTART    >hosta? ?abort
    romhere   >hosta? ?abort
    over - fileid write-file drop
    fileid close-file throw
    cr bin-file count type ."  done " ;

\  Build UF2 binary file for RP2040 bootloader
\
\   Based on the code from Willem Jager but simplyfied, W.O. 24jan2023

hex
10000000    value 'TARGET   \ Pico flash start address
0           value #BLOCKS   \ Total number of UF2 blocks
0           value BIN#      \ Binary size
uf2-buffer  value 'PTR      \ UF2 address pointer

: READ-SBOOT ( -- )     \ Open secundairy boot and image file, note size!
    s" boot-nof4b.bin" r/o bin open-file \ Add secundairy boot file
    abort" File failed " >r
    r@ file-size throw d>s to bin#
    binary-buffer 1000 r@ read-file throw drop
    r> close-file throw ;

: BC!+      ( b -- )    'ptr c!  'ptr 1+ to 'ptr ;  \ Store byte & advance
: B!+       ( x -- )    'ptr !   'ptr 4 + to 'ptr ; \ Store word & advance
: UF2-HEAD  ( blk# -- ) \ Store UF2 block header
    0A324655  b!+       \ Number 1, a string
    9E5D5157  b!+       \ Number 2
    00002000  b!+       \ Family ID
    'target   b!+       \ Destination address
    00000100  b!+       \ Data block size
    ( blk# )  b!+       \ Current block number
    #blocks   b!+       \ Total number of blocks
    E48BFF59  b!+ ;     \ RP2350 secure image ID
\   E48BFF56  b!+ ;     \ RP2040 family ID

: WRITE-BLOCK ( a1 block# -- a2 )
    uf2-head                    \ UF2 block header & Block addresses
    100 0 do  count bc!+  loop  \ Copy one binary block to UF2
    [ 200 124 - ] literal       \ Pad block with zero's
    0 do  0 bc!+  loop
    0AB16F30 b!+                \ And closing magic number
    'target 100 + to 'target ;  \ Increase destination address

: CALC-BLOCKS ( -- )
    romhere  >hosta? ?abort     \ Data for UF2 blocks calculation
    MSTART   >hosta? ?abort  -  \ Image length
    100 /mod swap 0 > 1 and +   \ Calc. & round UF2 blocks
    1+ to #blocks ;             \ Correct & save number of blocks

: BUILD-UF2   ( a -- )          \ Address range to convert
    binary-buffer 0 write-block drop \ Write secundairy boot to UF2
    MSTART   >hosta? ?abort     \ Write image behind it
    #blocks 1 ?do
        i .  i write-block           \ Write UF2 block 'i'
    loop  drop ;

: MAKE.UF2      ( -- )          \ Make uf2 file from binary image
    10000000 to 'target         \ Initialise UF2 converter
    uf2-buffer to 'ptr
    read-sboot   calc-blocks    \ Read secundairy boot
    build-uf2

    uf2-file count              \ Get UF2 file name
    w/o bin create-file         \ (Re)define UF2 file
    abort" File failed "  >r    \ Succeeded, save FID
    uf2-buffer 'ptr over -      \ Calc. file length to save
    r@ write-file throw         \ Write UF2-file
    r> close-file throw         \ Ready
    cr uf2-file count type ."  done " ;


forth
cr .(   metacompiler loaded   )
\ <><>
