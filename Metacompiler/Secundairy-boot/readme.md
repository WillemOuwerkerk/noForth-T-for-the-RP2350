<h1 align="center"> Using the noForth t metacompiler</h1>

**Single core meta:**
- Start Win32Forth
- Select the folder: Meta-solo
- include T-meta-2026-jul28.f
- include boot-nof4b.f
    - Type **.** key
          
The noForth T UF2 file is ready with the current date in the
filename, it includes sboot-nof4b.bin & the generated binary
example: noforth t RP2350 solo 260829.uf2


Note the meta compiler uses these files:
- noForth-T-asm-M33.f
- RP2040-DAS.f
- T-meta-2026-jul28.f
- boot-nof4b.f

The file <b>boot-nof4b.f</b> is the secundairy boot routine. It is used to generate <b>boot-nof4b.bin</b>.


**Take care:**

    In the target file a hard coded offsets & addresses are used.
    Please check the offset to the boot record field that signals
    the presence of a second binary.


