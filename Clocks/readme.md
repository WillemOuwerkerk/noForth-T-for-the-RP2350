# Alternative clock base for noForth t RP2350 

Change the SYS-CLK the system clock to another maximum frequency.
Note that! Not every board can handle a high system clock.
The word <code> KHZ </code> can be used to set the system clock to any frequency
between 10kHz and the configured maximum clock in 1kHz steps.

***

- [****48MHZ-base.f****](48MHZ-base.f) ; Set PLL output for system clock to 48MHz
- [****96MHZ-base.f****](96MHZ-base.f) ; Set PLL output for system clock to 96MHz
- [****144MHZ-base.f****](144MHZ-base.f) ; Set PLL output for system clock to 144MHz
- [****192MHZ-base.f****](192MHZ-base.f) ; Set PLL output for system clock to 192MHz
- [****240MHZ-base.f****](240MHZ-base.f) ; Set PLL output for system clock to 240MHz
- [****384MHZ-base.f****](384MHZ-base.f) ; Set PLL output for system clock to 384MHz
- [****432MHZ-base.f****](432MHZ-base.f) ; Set PLL output for system clock to 432MHz
- [****480MHZ-base.f****](480MHZ-base.f) ; Set PLL output for system clock to 480MHz
