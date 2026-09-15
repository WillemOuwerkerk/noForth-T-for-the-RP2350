## Configuration examples

These examples show how to configure the RP2350 to run at different frequencies, including a modest overclock. Keep in mind that the maximum system clock frequency that can be used is limited by the selected PLL frequency. If a frequency that is too high is specified, noForth t will limit it to the selected PLL frequency.


- Setting the system clock IN 10kHz steps, switch GPIO pin & LED
- Set the used UART base address
- Setting the baudrate
- Setting input address for S?
- The fifth cell is for noForth t's internal use, it notes
  if noForth t solo or noForth t duo is running

If the changes are correct, you can make them permanent using `FREEZE` (for the binary that is used to startup) 
or `FREEZE2` for the additional binary that launches when you type `COLD2`. The current noForth t settings are displayed when the file [****print-cfg-rp2350.f****](../Tools/print-cfg-rp2350.f)
is included.
