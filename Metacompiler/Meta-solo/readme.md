<h1 align="center"> Using the noForth t metacompiler</h1>

**Single core meta:**
- Start Win32Forth
- Select the folder: Meta-solo
- include T-meta-2026-jul28.f
- include T-targ-2350aug17a.f
    - Type **+** key (or - key for a version without vocabularies)
    - Type **.** key
          
The noForth T UF2 file is ready with the current date in the
filename, it includes sboot-nof4b.bin & the generated binary
example: noforth t RP2350 solo 260829.uf2


Note the meta compiler uses these files:
- noForth-T-asm-M33.f
- RP2040-DAS.f
- T-meta-2026-jul28.f
- T-targ-2350aug17a.f
- boot-nof4b.f
- boot-nof4b.bin

The file <b>boot-nof4b.f</b> is the secundairy boot routine. It is used to generate <b>boot-nof4b.bin</b>.


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


