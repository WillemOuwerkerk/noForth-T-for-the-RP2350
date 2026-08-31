\ Valid frequencies: 48, 96, 144, 192, 240, 288, 336, 384, 432 & 480MHz
\   decimal 144000000 , \ Selected PLL clock 144MHz
\   hex          0B0 h, \ Core on 1.1 Volt
\               6042 h, \ PLL feedback divisor & post dividers (1152)
\           1  3  b+b , \ PERI=1 (144mhZ) & ADC/USB=3 dividers
                        \ USB & ADC clock need to be 48MHz
\   decimal 192000000 , \ Selected PLL clock 192MHz
\   hex          0D0 h, \ Core now on 1.2 Volt
\               4041 h, \ PLL feedback divisor & post dividers (768)
\           2  4  b+b , \ PERI=2 (120mhZ) & ADC/USB=5 dividers
                        \ USB & ADC clock need to be 48MHz
\   decimal 240000000 , \ Selected PLL clock 240MHz
\   hex          0E0 h, \ Core now on 1.25 Volt
\               5041 h, \ PLL feedback divisor & post dividers
\           2  5  b+b , \ PERI=2 (120mhZ) & ADC/USB=5 dividers
                        \ USB & ADC clock need to be 48MHz
\   decimal 288000000 , \ Selected PLL clock 288MHz
\   hex          0F0 h, \ Core now on 1.30 Volt
\               6041 h, \ PLL feedback divisor & post dividers
\           2  6  b+b , \ PERI=2 (144mhZ) & ADC/USB=6 dividers
                        \ USB & ADC clock need to be 48MHz
\   decimal 336000000 , \ Selected PLL clock 336MHz
\   hex          100 h, \ Core now on 1.35 Volt
\               7041 h, \ PLL feedback divisor & post dividers
\           3  7  b+b , \ PERI=4 (112mhZ) & ADC/USB=7 dividers
                        \ USB & ADC clock need to be 48MHz
\   decimal 384000000 , \ Selected PLL clock 384MHz
\   hex          110 h, \ Core now on 1.4 Volt
\               8041 h, \ PLL feedback divisor & post dividers
\           3  8  b+b , \ PERI=3 (128mhZ) & ADC/USB=8 dividers
                        \ USB & ADC clock need to be 48MHz
\   decimal 432000000 , \ Selected PLL clock 432MHz
\   hex          130 h, \ Core now on 1.6 Volt
\               4821 h, \ PLL feedback divisor & post dividers
\           4  9  b+b , \ PERI=4 (108mhZ) & ADC/USB=9 dividers
                        \ USB & ADC clock need to be 48MHz
\   decimal 480000000 , \ Selected PLL clock 480Hz
\   hex          150 h, \ Core now on 1.7 Volt
\               5021 h, \ PLL feedback divisor & post dividers
\           4 0A  b+b , \ PERI=4 (120mhZ) & ADC/USB=10 dividers
                        \ USB & ADC clock need to be 48MHz

v: inside
MAX-CLK
dm 144,000,000  over !  cell+       \ PLL clock
hx B0           over h! 2 +         \ Core voltage 1V
hx 6042         over h! 2 +         \ PLL dividers
1 3 b+b         swap !              \ Peripheral & USB/ADC clock

4 cfg @ [if]                        \ Is it a duo version?
    ramborder 3C44 + >r             \ MAX-CLK of core1
    MAX-CLK @+  r@  !               \ Copy clock table
    @+          r@ cell+  !
    @           r> cell+ cell+ !
[then]

max-clk @ dm 10000 /  0 cfg 2 + h!  \ Set maximum clock freq.

4 cfg @  abs  4 cfg !               \ Restart


v: fresh
config  led

\ End ;;;
