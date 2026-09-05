<h1 align="center"> Using the noForth t metacompiler</h1>

**Single core meta:**
- Start Win32Forth
- Select the folder: meta solo xxx
- include T-meta xxx.f
- include T-targ xxx.f
    - Type **+** key (or - key for a version without vocabularies)
    - Type **.** key
          
The noForth T UF2 file is ready with the current date in the
filename, it includes sboot-nof2.bin & the generated binary
example: noforth t RP2350 230429.uf2


Note the meta compiler uses these files:
- noForth-T-asm-M33
- RP2040-DAS
- T-meta-2026-...
- T-targ-2350...
- boot-nof4b.bin

**Take care:**

    In the target files sometimes hard coded offsets & addresses are used.
    Especially the duo versions because they address each other too.

    FREEZE  The offset to DP, now: 0120
            also to the storage lcation for the clock frequency now: 0 CFG 2 +

    BAUD    The offset to clock frequency: CFG> 2 +
    >PLL    Idem
    CONFIG  Idem multiple time and: RAMBORDER 10A +
            Optional: RAMBORDER XXXX + BOOT1

    Check all usage of CFG and CFG> too

<h1 align="center"> Waveshare RP2350-PiZero </h1>
Uses only 3.5mA with the PLL and system clock on 48MHz and about 1.5mA on with the system clock on 16MHz.
The USB-CDC is still functioning and all timing stays correct.
<br><br>
<img width="1326" height="1029" alt="afbeelding" src="https://github.com/user-attachments/assets/43e061bf-0982-40bd-8ca2-8110a3113e08" />
