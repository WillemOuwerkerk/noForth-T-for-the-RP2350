(* Timing of code parts
here 0 , >r             \ Storage for timing
create KICKOFF ( -- )
    400B0028 ,          \ Timer0
    r@ ,                \ Storage address
code>
    w  { hop day } ldm,
    w  hop ) ldr,
    w  day ) str,
    next,
end-code

create PASSED ( -- µs )
    400B0028 ,          \ Timer0
    r> ,                \ Storage address
code>
    w  { hop day } ldm,
    tos  sp -) str,
    tos  hop ) ldr,
    sun  day ) ldr,
    tos sun subs,
    next,
end-code
*)

hex

v: inside also definitions
here 0 , >r     \ Storage for timing

create KICKOFF  ( --  )         \ Save Timer0
   400B0028 ,  r@ ,             \ Timer & storage location
code>
    6822CA30 ,  C804602A ,  46A7CA10 ,
end-code

create PASSED   ( -- µs )       \ Calculate time passed in µs or cycles
    400B0028 ,  r> ,            \ Timer0 & storage location
code>
    3904CA30 ,  6823600B ,  1B9B682E ,
    CA10C804 ,  FFFF46A7 ,
end-code

: .TIME         ( -- )          \ Print time passed in millisec.
    passed  hx 3E8 /mod  cr     \ Divide by 1000
    0 <# #s #> type ." ,"       \ First print MS
    0 <# # # # #> type ."  millisec. " ; \ Then µS behind the comma

v: forth definitions
: MEASURE       ( "name" -- )   \ Time the pace of code "name" in µsecs
    0 400B0038 !  1 ms  base @ >r
    '  kickoff  catch drop
    decimal .time  r> base ! ;

: CYCLES        ( "name" -- )   \ Time the pace of code "name" in cycles
    1 400B0038 !                \ Enable as cycle counter
    base @ >r  '  kickoff  catch drop
    decimal passed dm 113 - ( test correction ) . ." Cycles "  
    r> base !  0 400B0038 ! ;   \ Restore to microsec. counter

v: fresh
shield MEASURE\
