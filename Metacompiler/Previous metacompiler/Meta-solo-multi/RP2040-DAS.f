(* RP2040 ASM basic opcodes, DAS vsn 0.5a: ~6400 Bytes with most registers double, & ITC macro's
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
Branches:em
    Opco cccc  bbbbbbbb    Conditional branch   
    Opcod   bbbbbbbbbbb    Branch
    Opcode.. x mmmm 000    BX & BLX (Special case of 2 register, all)
32-bit opcodes:
    Opcode...... nnnn ........ rrrrrrrr     2 registers, all
    Opcode.. ........ ........ ........     Whole 32-bits pattern
    Opcod S .......... .J.J ...........     Branch & link
*)

 here  hex  vocabulary DASM  \ noForth additions
0 value PURE?
: REG  true to pure? ;  : NOF  false to pure? ;

  dasm also  definitions    \ Add register names & addressing modes
\ : ABORT"  ( flag ccc -- )
\   postpone if  postpone ."  postpone abort  postpone then ; immediate
\ : MHERE   chere ;

  forth definitions \ Win32Forth & Gforth additions
: .HEX      ( u -- )            \ Cell wide version of .HEX uses four or more digits
    base @ >r  hex  0 <# # # # #s #> type space  r> base ! ;  dasm
\ : H,    dup c, 100 / c, ;             \ Gforth
\ : H,    w, ;                          \ win32Forth
  : .DEC    base @  swap  decimal .  base ! ;
  : B+B     100 * or ;
\ : H@      w@ ;       : H!      w! ;   \ Win32Forth & Gforth
  : H-H     dup FFFF and  swap 10 rshift ;
\ : MHERE   here ;

: -TRAILING ( a +n1 -- a +n2 )  \ Cut trailing spaces from a string
    begin  2dup + 1- c@ bl = while  1-  repeat ;

  dasm definitions
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
    pure? if                \ Print register names
        dup 0D < if  ." r"  .dec  exit then
        0D - 3 * s" rsplr pc " drop  + 3 type space exit
    then
    0F and  4 *
    s" ip  sp  w   tos hop day sun moonww  xx  yy  zz  doesrp  lr  pc  "
    drop +  4 -trailing type space ;
\ opc = opcode, s = shift, m = mask, w = width (multiplier) 
: .REG      ( opc s m -- )      >r  rshift  r> and .reg) ;  \ Decode any reigster field
: .LDREG    ( opc -- )          dup 7 and  swap 80 and 4 rshift or .reg) ; \ Decode long dest reg.
: .DSREG    ( opc -- )          dup 0 7 .reg  3 7 .reg ;    \ Decode dest. & source register
: @LIT      ( opc s m -- +n )   >r  rshift  r> and ;        \ Read any constant field
: .INDIRECT ( opc s m w -- )    >r  @lit  r> * u. ;         \ Decode constant index
: .CONSTANT ( opc s m w -- )    .indirect ." # " ;          \ Decode any constant type field
: .CONST    ( opc s m -- )      1 .constant ;               \ Simple constant
: .JUMP     ( a o -- )          2*  dup .  ." to " over 4 + + .hex ; \ Calculate jump address
: .REG[]    ( opc w -- )        \ Indexed with offset
    >r  dup 0 7 .reg  dup 3 7 .reg  6 1F r> .indirect  ." #) " ;
: .REGS     ( opc a u f -- )    \ Decode multiple register fields
    ." { "  if  2dup type  then  2drop  \ First special register
    FF and  8 0 do
        dup  1 i lshift and
        if  i .reg)  then
    loop  drop  ." } " ;

: .BL       ( a opc -- a )      \ Branch & link
    dup 4000000 and 0= 0= >r        \ Make & save sign
    -1 7FFFFF xor                   \ Extend sign   opc mask
    r@ and   over 7FF and   or      \ Bit 0 to 10   opc bl..
    over 3FF0000 and 5 rshift  or   \ Bit 11 to 21  opc bl..
    swap -1 xor r> xor  2800 and    \ Isolate bit 21 & 22
    dup >r 800 and A lshift  or     \ Add bit 21
    r> 2000 and 9 lshift or .jump ." bl " ; \ & bit 22

: .BEXX     ( opc -- )      \ Hint & breakpoint opcodes
    dup BF00 = if  ." nop "    then
    dup BF10 = if  ." yield "  then
    dup BF20 = if  ." wfe "    then
    dup BF30 = if  ." wfi "    then
    dup BF40 = if  ." sev "    then
    dup FF00 and  BE00 = if
    0 FF .const  ." bkpt "  else  drop  then ;

: .SXT      ( opc -- )      \ Sign extend opcodes
    dup .dsreg 01C0 and  6 rshift  4 *  s" sxthsxtbuxthuxtb"
    drop +  4 type space ;

: .REV      ( opc -- )      \ Invert opcodes
    dup .dsreg  00C0 and >r
    r@ 0=     if  ." rev "     then
    r@ 0040 = if  ." rev16 "   then
    r> 00C0 = if  ." revsh "   then ;

: .LOGIC    ( opc -- )      \ Logical opcodes
    dup 03C0 and  6 rshift >r  .dsreg  r@ 9 = if  ." #0 "  then  r> 4 *
    s" andseorslslslsrsasrsadcssbcsrorstst rsbscmp cmn orrsmulsbicsmvns"
    drop +  4 -trailing type space  ;

: .BX       ( opc -- )      \ Branch using registers
    dup 3 F .reg  80 and if ." blx " else ." bx " then ;

: .RSP      ( opc -- )      \ Return stack opcodes with 7-bits number
    dup ." rp "  0 7F .const  0080 and if ." sub " else ." add " then ;
 
: .0XXX     ( opc -- )      \ Shift opcodes with 5-bits number
    dup .dsreg  dup 6 1F .const  800 and if ." lsrs " else ." lsls " then ;

: .1XXX     ( opc -- )      \ Shift, add & subtract
    dup 0800 and 0= if dup .dsreg  6 1F .const ." asrs " exit then
    dup 0E00 and >r
    r@ 0800 = if dup .dsreg  6 7 .reg ." adds.mv " then
    r@ 0A00 = if dup .dsreg  6 7 .reg ." subs.mv " then
    r@ 0C00 = if dup .dsreg  6 7 .const ." adds.mv " then
    r> 0E00 = if dup .dsreg  6 7 .const ." subs.mv " then ;

: .2XXX     ( opc -- )      \ Compare & move using 8-bits number
    dup 8 7 .reg  dup 0 FF .const  0800 and if ." cmp " else ." movs " then ;
    
: .3XXX     ( opc -- )      \ Subtract & add using 8-bits number
    dup 8 7 .reg  dup 0 FF .const  0800 and if ." subs " else ." adds " then ;

: .CH       ( ch -- )       dup 7F u< and  bl max emit ; \ Print byte as character
: .TEXT     ( a -- )        count .ch c@ .ch  space ;   \ Show half word as ASCII text
: .POOL     ( a1 a2 +n -- )
    5 < if
        cr  >r  2 + dup >targa? ?abort  .hex  
        dup .text  dup 16@ .hex  space  ." ahead"
        dup 2 + r> <> if
            cr  2 + dup >targa? ?abort  .hex
            dup .text  dup 16@ .hex  space  ." noop" 
        then
        cr  2 + dup >targa? ?abort  .hex
        dup .text  dup 16@ .hex  space
        cr  2 + dup >targa? ?abort  .hex
        dup .text  dup 16@ .hex  space
    else  drop  then ;

: .4XXX     ( a opc -- a )  \ Bulk of all opcodes are decoded here
    dup 0800 and if
        dup 8 7 .reg  0 FF @lit 4 *  ." pc "    \ Show destination register
        >r  r@ dup u. ." #) ldr "  over +  4 +  \ Get literal & calc. address of literal
        dup 4 mod -  dup @  ."  Lit: " .hex     \ Correct for not aligned address & show literal
        r> .pool  exit
    then
    dup 0C00 and 0= if  .logic  exit  then  \ All basic logic opcodes
    dup 0300 and  dup 0300 = if  drop .bx  exit  then >r \ BX & BLX
    dup .ldreg  3 F .reg  r> 8 rshift  3 *  
    s" addcmpmov" drop  +  3 type space ;   \ All register opcodes

: .5XXX     ( a opc -- a )  \ Load & store using registers
    dup 0 7 .reg  dup 3 7 .reg  dup 6 7 .reg ." r) "
    0E00 and  9 rshift  5 *
    s" str  strh strb ldrsbldr  ldrh ldrb ldrsh" drop +
    5 -trailing type space ;

: .6XXX     ( a opc -- a )  \ Load & store 32-bits using 5-bits offest
    dup 4 .reg[]  0800 and if ." ldr " else ." str " then ;

: .7XXX     ( a opc -- a )  \ Load & store 8-bits using 5-bits offest
    dup 1 .reg[]  0800 and if ." ldrb " else ." strb " then ;

: .8XXX     ( a opc -- a )  \ Load & store 16-bits using 5-bits offest
    dup 2 .reg[]  0800 and if ." ldrh " else ." strh " then ;

: .9XXX     ( a opc -- a )  \ Load & store 32-bits using 5-bits offest
    dup 8 7 .reg  ." rp "  dup 0 FF 4 .indirect ." #) "
    0800 and if ." ldr " else ." str " then ;

: .AXXX     ( a opc -- a )  \ Add 8-bits number to RP & PC
    dup 8 7 .reg  dup 0800 and if  ." rp "  0 FF .const ." add "
    else  ." pc "  0 FF .const ." adr " 
    then ;
   
: .BXXX     ( opc -- )      \ Miscellaneous opcodes, PUSH, POP, etc.
    dup 0E00 and >r
    r@ 0=     if  .rsp  then
    r@ 0200 = if  .sxt  then
    r@ 0400 = if  s" lr " 2 pick 100 and .regs  ." push "  then
    r@ 0600 = if  ." cpsi" 10 and if ." d " else ." e "  then  then
    r@ 0800 = if  ." udf "  drop  then
    r@ 0A00 = if  .rev     then
    r@ 0C00 = if  s" pc " 2 pick 100 and .regs  ." pop "  then
    r> 0E00 = if  .bexx   then ;

: .CXXX     ( opc -- )      \ Load & store multiple registers
    dup 8 7 .reg  dup 0 0 0 .regs  0800 and if ." ldm " else ." stm " then ;

: .DXXX     ( a opc -- a )  \ Branch & test opcodes & supervisor mode
    dup 0F00 and  8 rshift >r  r@ 0D > if  0 FF .const  else
        FF and dup 80 and if  -1 FF xor  or  then  .jump
    then  r> 3 *  s" beqbnebcsbccbmibplbvsbvcbhiblsbgebltbgtbleudfsvc"
    drop +  3 type space ;

: .EXXX     ( a opc -- )    \ Branch eleven bits
    7FF and  dup 400 and if  -1 7FF xor  or  then  .jump ." b "  ;

: .FXTRA    ( a -- a )    cr dup >targa? drop .hex  dup .text ;
: .FXXX     ( a1 opc -- a2 ) \ 32-bits opcodes (coupled opcodes) like BL, etc.
    10 lshift  over 2 + 16@ >r r@ or \ Build 32-bits opcode
    dup F800F000 and  F0008000 = if \ Valid 32-bits opcode?
        dup 003FFFC0 and  003F8F40 = if \ Barrier opcode?
            30 and 4 rshift  3 *    \ Yes, decode
            s" dsbdmbisbudf" drop + 3 type space
        else
            dup 00700000 and >r     \ No, Move special or UDF?
            r@ 00700000 = if  drop  ." udf "  then
            r@ 00600000 = if  dup 8 F .reg  .special ." mrs "   then
            r> 0= if  dup .special  10 F .reg ." msr "   then
        then  2 +  cr dup .hex  dup .text  r> .hex  exit
    then
    dup F800D000 and F000D000 <> 
    if  drop  ." udf "  2 +  .fxtra  r> .hex  exit  then
    .BL  2 +  .fxtra  r> .hex ;

create 'OPC ' .0xxx ,  ' .1xxx ,  ' .2xxx ,  ' .3xxx ,  ' .4xxx ,
            ' .5xxx ,  ' .6xxx ,  ' .7xxx ,  ' .8xxx ,  ' .9xxx ,
            ' .Axxx ,  ' .Bxxx ,  ' .Cxxx ,  ' .Dxxx ,  ' .Exxx ,  ' .Fxxx ,

forth definitions
: MDAS)     ( a -- )
    begin
        cr dup >targa? ?abort  .hex  
        dup .text  dup 16@ .hex  space  \ a
        dup 16@  dup F000 and  0C rshift             \ a opc offset
        cells 'opc +  @ execute  2 +                 \ a+2
    key 20 <> until  drop ;

cr .( Thumb disassembler ) here swap - .dec  \ End
