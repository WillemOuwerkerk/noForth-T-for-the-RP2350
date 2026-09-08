<h1 align="center"> noForth t metacompiler overview</h1>

- [noForth t solo](Meta-solo) ; noForth for a single core without multitasker
- [noForth t duo](Meta-duo) ; noForth for a dual core without multitasker
- [noForth t solo multi](Meta-solo-multi) ; noForth for a single core with multitasker
- [noForth t duo multi](Meta-duo-multi) ; noForth for a dual core with multitasker

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

<br>
<h2 align="center"> Waveshare RP2350-PiZero </h2>
Uses only 3.5mA with the PLL and system clock on 48MHz and about 1.5mA on with the system clock on 16MHz.
The USB-CDC is still functioning and all timing stays correct.

<br><br>
<img width="1326" height="1029" alt="afbeelding" src="https://github.com/user-attachments/assets/43e061bf-0982-40bd-8ca2-8110a3113e08" />
