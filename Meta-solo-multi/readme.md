
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
example: noforth t 230429.uf2


Note the meta compiler uses these files:
- RP2040-opcodes.W32
- RP2040-DAS
- T-meta...
- T-Targ...
- boot-nof2.bin

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
