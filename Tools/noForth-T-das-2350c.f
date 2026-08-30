(* (c) W.O. 2023, RP2350 ASM basic opcodes, vsn 0.7: 8712 Bytes

Immediate:
    Opcod ddd iiiiiiii      8-bit immediate, 1 register, low
    Opcode.... iiiiiii      7-bit immediate, RP implicit
    Opcod iiiii mmm ddd     5-bit immediate, 2 registers, low
    Opcode. iii nnn ddd     3-bit immediate, 2 registers, low
Register:
    Opcode.. d .... ddd     1 register, all
    Opcode....  mmm ...     1 register, low
    Opcode....  mmm ddd     2 registers, low
    Opcode. mmm nnn ddd     3 registers, low
    Opcode.. d mmmm ddd     2 registers, all
    Opcode...  mmmm ...     1 register, all
Push, Pull:
    Opcode.  M rrrrrrrr     R0 to R7 & LI/PC (special case of 8-bit imm)
Diversen:
    Opcode..   ...i....     CPS (Whole 16-bits pattern)
    Opcode..   iiiiiiii     BKP & SVC (Special case of 8-bit imm)
    Opcode..   ........     Whole 16-bits pattern
Branches:
    Opco cccc  bbbbbbbb    Conditional branch
    Opcode i. iiiii nnn    CBZ & CBNZ
    Opcod   bbbbbbbbbbb    Branch
    Opcode.. x mmmm 000    BX & BLX (Special case of 2 register, all)
32-bit opcodes:
    Opcode...... nnnn ........ rrrrrrrr     2 registers, all
    Opcode.. ........ ........ ........     Whole 32-bits pattern
    Opcod S .......... .J.J ...........     Branch & link
    Opcode.. ....nnnn llll hhhh....mmmm     UMULL, SMULL MLS, etc.
    Opcode.. ....2222 tttt ccccoooorrrr     MRCC & MRRC
*)

' see drop  \ Needs SEE pritives!

here  hex
v: inside also  extra definitions
[undefined] short? [if]  false value SHORT?  [then]
0 value REAL?   \ True when original register names must be used
v: inside definitions
: .DATA     ( +n -- )
    cr >r  short? 0= if
        'see 0A u.r ." : "               \ .adr
        'see r@ for c@+ pchar emit next drop    \ .4chars
        'see r@ 4 = if @ 0B else h@ 5 then      \ .contents 32/16 bits
        u.r
    then  space space  rdrop ;

v: extra definitions
: .HEX      ( u -- )            \ Cell wide version of .HEX uses four or more digits
    base @ >r  hex  0 <# # # # #s #> type space  r> base ! ;  v: inside
\ : .DEC      ( u -- )    base @  swap  decimal .  base ! ;

v: forth definitions
: -TRAILING ( a +n1 -- a +n2 )
    begin  1-  2dup + c@ BL <> until  1+ ;

v: inside definitions
: .SPECIAL  ( opc -- )
    FF and  dup 0A < if
        5 * s" apsr iapsreapsrxpsr ???  ipsr epsr iepsrmsp  psp  "
        drop  +  5
    else
        dup 10 = if  drop  00  else
        14 = if  8  else  10  then  then
        s" primask control reserved" drop  +  8
    then  -trailing type space ;
: .REG)     ( r -- )                \ Print register names
    0F and  4 *  real? if
        s" r0  r1  r2  r3  r4  r5  r6  r7  r8  r9  r10 r11 r12 sp  lr  pc  "
    else
        s" ip  sp  w   tos hop day sun moonww  xx  yy  zz  doesrp  lr  pc  "
    then  drop +  4 -trailing type space ;
: .REG      ( opc s m -- )    >r  rshift  r> and .reg) ;  \ Any register field
: .LDREG    ( opc -- )        dup 7 and  swap 80 and 4 rshift or .reg) ; \ Long
: .DSREG    ( opc -- )        dup 0 7 .reg  3 7 .reg ;    \ Decode dest. & src
: @LIT      ( opc s m -- +n ) >r  rshift  r> and ;        \ Any constant field
: .INDIRECT ( opc s m w -- )  >r  @lit  r> * u. ;         \ Constant index
: .CONSTANT ( opc s m w -- )  .indirect ." # " ;          \ Constant type field
: .CONST    ( opc s m -- )    1 .constant ;               \ Simple constant
: .JUMP     ( offset -- )     2*  dup .  ." to " 'see cell+ +  .hex ; \ Calc. jump
: COMMA     ( -- )            ." , " ;
: CTYPE     ( a +n -- )       type  comma ;
: .REG[]    ( opc w -- )        \ Indexed with offset
    >r  dup 0 7 .reg  dup 3 7 .reg  6 1F r> .indirect  ." #) " ;
: .REGS     ( opc a u f -- )    \ Decode multiple register fields
    ." { "  if  2dup type  then  2drop  \ First special register
    FF and  8 0 do
        dup  i bitmask and  ( 1 i lshift and )
        if  i .reg)  then
    loop  drop  ." } " ;

: .BL       ( opc -- )      \ Branch & link
    dup 4000000 and 0<> >r          \ Make & save sign          opc
    -1 7FFFFF xor                   \ Extend sign   opc mask    opc 'a
\   r@ [ -1 7FFFFF xor ] literal and
    r@ and   over 7FF and   or      \ Bit 0 to 10   opc bl..    opc 'a
    over 3FF0000 and 5 rshift  or   \ Bit 11 to 21  opc bl..    opc 'a
    swap -1 xor r> xor  2800 and    \ Isolate bit 21 & 22       'a msk
    dup >r 800 and A lshift  or     \ Add bit 21
    r> 2000 and 9 lshift or .jump ." bl, " ; \ & bit 22

: .HINTS    ( opc -- )      \ Hint & breakpoint opcodes
    dup BF00 = if  ." nop"    then
    dup BF10 = if  ." yield"  then
    dup BF20 = if  ." wfe"    then
    dup BF30 = if  ." wfi"    then
    dup BF40 = if  ." sev"    then
    dup FF00 and  BE00 = if
    0 FF .const  ." bkpt"  else  drop  then comma ;

: .SXT      ( opc -- )      \ Sign extend opcodes
    dup .dsreg 1C0 and  6 rshift  4 *  s" sxthsxtbuxthuxtb"
    drop +  4 ctype ;

: .REV      ( opc -- )      \ Invert opcodes
    dup .dsreg  00C0 and >r
    r@ 0=   if  ." rev"     then
    r@ 40 = if  ." rev16"   then
    r> C0 = if  ." revsh"   then  comma ;

: .LOGIC    ( opc -- )      \ Logical opcodes
    dup 3C0 and  6 rshift >r  .dsreg  r@ 9 = if  ." #0 "  then  r> 4 *
    s" andseorslslslsrsasrsadcssbcsrorstst rsbscmp cmn orrsmul bicsmvns"
    drop +  4 -trailing  ctype ;

: .CBZ      ( opc -- )      \ Compare & branch on zero/nonzero
    >r  r@ 3 1F @lit  r@ 400 and 4 rshift or .jump  r> 0 7 .reg  ;

: .BX       ( opc -- )      \ Branch using registers
    dup 3 F .reg  80 and if ." blx" else ." bx" then comma ;

: .RSP      ( opc -- )      \ Return stack opcodes with 7-bits number
    dup ." rp "  0 7F .const  80 and if ." sub" else ." add" then  comma ;

: .MOVX     ( opc a u -- )  \ Decode MOVW & MOVT
    2>r  >r r@  r@ 8 F .reg                 \ a1
    r@ FF and  r@ 7000 and 4 rshift or      \ a1 +n
    r@ 04000000 and F rshift or             \ a1 +n
    r> F0000 and 4 rshift or .  2r> type    \ a1 
    2 +to 'see  short? 0= if 2 .data  then  drop ;             \ -

: .0XXX     ( opc -- )      \ Shift opcodes with 5-bits number
    dup .dsreg  dup 6 1F .const  800 and if ." lsrs.mv, " else ." lsls.mv, " then ;

: .1XXX     ( opc -- )      \ Shift, add & subtract
    dup 800 and 0= if dup .dsreg  6 1F .const ." asrs.mv, " exit then
    dup E00 and >r
    r@ 800 = if dup .dsreg  6 7 .reg ." adds.mv, " then
    r@ A00 = if dup .dsreg  6 7 .reg ." subs.mv, " then
    r@ C00 = if dup .dsreg  6 7 .const ." adds.mv, " then
    r> E00 = if dup .dsreg  6 7 .const ." subs.mv, " then ;

: .2XXX     ( opc -- )      \ Compare & move using 8-bits number
    dup 8 7 .reg dup 0 FF .const  800 and if ." cmp, " else ." movs, " then ;

: .3XXX     ( opc -- )      \ Subtract & add using 8-bits number
    dup 8 7 .reg dup 0 FF .const  800 and if ." subs, " else ." adds, " then ;

: .4XXX     ( opc -- )      \ Bulk of all opcodes are decoded here
    dup 800 and if
        dup 8 7 .reg  0 FF @lit 4 * ." pc " \ Show destination register
        dup u. ." #) ldr, "  'see +  cell+  \ Get lit. & calc. address
        dup 4 mod -  @ .hex  ." ##" exit    \ Show inline literal
    then
    dup C00 and 0= if  .logic  exit  then   \ All basic logic opcodes
    dup 300 and  dup 300 = if  drop .bx  exit  then >r \ BX & BLX
    dup .ldreg  3 F .reg  r> 8 rshift  3 *
    s" addcmpmov" drop  +  3 ctype ;        \ All register opcodes

: .5XXX     ( opc -- )      \ Load & store using registers
    dup 0 7 .reg  dup 3 7 .reg  dup 6 7 .reg ." r) "
    E00 and  9 rshift  5 *
    s" str  strh strb ldrsbldr  ldrh ldrb ldrsh" drop +
    5 -trailing ctype ;

: .6XXX     ( opc -- )      \ Load & store 32-bits using 5-bits offest
    dup 4 .reg[]  800 and if ." ldr" else ." str" then comma ;

: .7XXX     ( opc -- )      \ Load & store 8-bits using 5-bits offest
    dup 1 .reg[]  800 and if ." ldrb, " else ." strb, " then ;

: .8XXX     ( opc -- )      \ Load & store 16-bits using 5-bits offest
    dup 2 .reg[]  800 and if ." ldrh, " else ." strh, " then ;

: .9XXX     ( opc -- )      \ Load & store 32-bits using 5-bits offest
    dup 8 7 .reg  ." rp "  dup 0 FF 4 .indirect ." #) "
    0800 and if ." ldr" else ." str" then  comma ;

: .AXXX     ( opc -- )      \ Add 8-bits number to RP & PC
    dup 8 7 .reg  dup 800 and if  ." rp "  0 FF .const ." add"
    else  ." pc "  0 FF .const ." add"
    then  comma ;

: .BXXX     ( opc -- )      \ Miscellaneous opcodes, PUSH, POP, etc.
    dup F00 and >r
    r@ 0=    if  .rsp  then
    r@ 100 =  r@ 300 = or if  .cbz ." cbz, "  then
    r@ 200 = if  .sxt  then
    r@ 400 = if  s" lr " 2 pick 100 and .regs  ." push, "  then
    r@ 600 = if  ." cpsi" 10 and if ." d, " else ." e, "  then  then
    r@ 800 = if  ." udf, "  drop  then
    r@ 900 = r@ B00 = or if  .cbz ." cbnz, "  then
    r@ A00 = if  .rev     then
    r@ C00 = if  s" pc " 2 pick 100 and .regs  ." pop, "  then
    r> E00 = if  .hints   then ;

: .CXXX     ( opc -- )      \ Load & store multiple registers
    dup 8 7 .reg  dup 0 0 0 .regs  800 and if ." ldm" else ." stm" then comma ;

: .DXXX     ( opc -- )      \ Branch & test opcodes & supervisor mode
    dup 0F00 and  8 rshift >r  r@ 0D > if  0 FF .const  else
        FF and dup 80 and if  -1 FF xor  or  then  .jump
    then  r> 3 *  s" beqbnebcsbccbmibplbvsbvcbhiblsbgebltbgtbleudfsvc"
    drop +  3 ctype ;

: .MXRX     ( opc a u -- )  \ Decode MCRR & MRRC
    2>r  >r r@ 8 F ." c" @lit .  R@ 4 F ." o" @lit .
    r@ C F .reg  r@ 10 f .reg  r> 0 F ." r" @lit .
    2r> type  2 +to 'see  short? 0= if 2 .data  then ;

\ EC4x,xxxx = MCRR      EC5x,xx1x = MRRC  E0xx,xxxx = B
: .EXXX     ( opc -- )       \ Branch eleven bits
    dup FF00 and                                \ opc msk
    EC00 = if                                   \ opc
        10 lshift  'see 2 + h@  or              \ Build 32-bits opcode
        dup F00000 and                          \ opc msk
        dup 400000 = if                         \ opc msk
            drop  s" mcrr, " .mxrx  exit
        then                                    \ opc msk
        500000 = if                             \ opc
            s" mrrc, " .mxrx  exit
        then
        drop ." udf, " exit
    then                                        \ Branch eleven bits
    7FF and  dup 400 and if  -1 7FF xor  or  then  .jump ." b, "  ;

: .FBYX     ( opc a u -- )  \ Decode MLS, SMULL, etc.
    2>r  >r r@ 8 F .reg  r@ 10 F .reg
    r@ 0 F .reg  r> C rshift F and  dup F < \ not UDIV or SDIV?
    if  dup .reg)  then  drop  2r> type
    2 +to 'see  short? 0= if 2 .data  then ;

\ F24i,idii = MOVW      F2Ci,idii = MOVT        Fiii,Diii = BL
\ FB0n,ad1m = MLS       FB8n,lh0m = SMULL
\ FB9n,FdFm = SDIV      FBAn,lh0m = UMULL       FBBn,FdFm = UDIV
: .FBxx     ( opc -- )
    dup FF000000 and                            \ opc msk
    F2000000 = if
        dup F00000 and                          \ opc msk
        dup 400000 = if                         \ opc msk
            drop  s" # movw, " .movx  exit
        then
        C00000 = if  s" # movt, " .movx  exit  then
        drop ." udf, "  exit
    then
    dup FF000000 and                            \ opc msk
    FB000000 = if
        dup F00000 and  dup 0=
        if  drop  s" mls, " .fbyx  exit    then
        dup 800000 =
        if  drop  s" smull, " .fbyx  exit  then
        dup 900000 =
        if  drop  s" sdiv, " .fbyx  exit   then
        dup A00000 = 
        if  drop  s" umull, " .fbyx  exit  then
    then 
    drop ." udf, " ;

: .Fxxx     ( opc -- )      \ 32-bits opcodes (coupled opcodes) like BL, etc.
    10 lshift  'see 2 + h@  or      \ Build 32-bits opcode
    dup F800F000 and  F0008000 = if \ Valid 32-bits opcode?
        dup 3FFFC0 and  3F8F40 = if \ Barrier opcode?
            30 and 4 rshift  3 *    \ Yes, decode
            s" dsbdmbisbudf" drop + 3 ctype
        else
            dup 700000 and >r       \ No, Move special or UDF?
            r@ 700000 = if  drop  ." udf"  then
            r@ 600000 = if  dup 8 F .reg  .special ." mrs"   then
            r> 0= if  dup .special  10 F .reg ." msr"   then
        then  comma  2 +to 'see  short? 0= if 2 .data  then  exit
    then
    dup F800D000 and F000D000 = if  .bl  else
        dup F2000000 and F2000000 = if  .FBxx  exit  then
    then  2 +to 'see  short? 0= if 2 .data  then ;

create 'OPC ' .0xxx ,  ' .1xxx ,  ' .2xxx ,  ' .3xxx ,  ' .4xxx ,
            ' .5xxx ,  ' .6xxx ,  ' .7xxx ,  ' .8xxx ,  ' .9xxx ,
            ' .Axxx ,  ' .Bxxx ,  ' .Cxxx ,  ' .Dxxx ,  ' .Exxx ,  ' .Fxxx ,

\ Leave address when CFA with pool behind it
: SKIP-CFA  ( -- 0|a )
    'see 4 mod if  0  exit  then    \ Zero when not aligned
    'see @  'see dup 28 + within if \ Max. 8 cell literals
        'see @+ tuck <              \ Code starts not behind CFA
        if      cell +to 'see  exit \ Yes skip CFA & to literal pool
        then    to 'see             \ Go on after CFA
    then  0 ;                       \ Nothing on other cases

: .HEAD     ( a +n -- )
    >r  dup c@ 7F and 20 < if       \ Yes, show it's a words name
        cr ." name " dup @name 2dup type
        r@ +to 'see
        nip 5 + 1C and +to 'see
    then  r> 2drop ;

: .ONELINE  ( 0|a -- )
    begin
    'see over -2 and < while            \ Until all literals done
        short? 0= if
            2 .data  2 +to 'see
        else
            'see 4 mod 0= if
                2 .data
            then  2 +to 'see
        then
        'see 4 mod if  'see 2 - @ .hex  then
    repeat
    dup 1 and if  drop cr ." code>"     \ Data definition end
    else if  cr ." data)" then          \ Inline data field end
    then  2 .data
    'see dup h@  dup F000 and  0C rshift        \ a opc offset
    cells 'opc +  @ execute drop  2 +to 'see ;  \ -

: DATA?     ( -- 0|a )                  \ Show (inline) data pool
    skip-cfa  ?dup 0= if
        'see h@+ 467A =                 \ is it: W PC MOV,
        over h@ FFFF <> and             \ Not FFFF
        swap h@ FC00 and E000 = and if  \ and: AHEAD,
            'see 2 + h@ 7FF and 2* 'see 6 + + \ Yes, calc. end of data block
            0 .oneline  0 .oneline      \ Show preceeding opcodes
            cr ." (data"  exit          \ It's an inline data field
        then  false  exit               \ No, it's something else
    then  1 or ;                        \ Not inline, it's a CFA with data pool

v: forth definitions
: MDAS      ( a -- )
    to 'see
    1 for
        'see cell+ ?head ?dup       \ Check for HEADER too?
        if      4 .head
        else    'see 6 + ?head ?dup \ Aligned header?
                if  'see h@ FFFF =
                    if  dup 6 .head  then drop
                then
        then    data? .oneline
    recur  next ;

: DAS       ( "name" -- )    '  mdas ;

v: fresh
shield DAS\     \ freeze
here swap - dm .

\ End
