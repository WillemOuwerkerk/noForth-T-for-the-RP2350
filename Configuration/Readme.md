## Configuration examples

These examples show how to set the RP2350 to several frequencies including moderest overclocking. Please note that the maximum system clock frequency that can be used is limited by the selected PLL frequency. If a frequency that is too high is specified, noForth will limit it to the selected PLL frequency.


- Setting the system clock IN 10kHz steps, switch GPIO pin & LED
- Set the used UART base address
- Setting the baudrate
- Setting input address for S?
- The fifth cell is for noForth t's internal use, it notes
  if noForth t solo or noForth t duo is running

When the changes are correct you may make them permanent by using `FREEZE` (for the booted core) 
or `FREEZE2` for the auxillary core that boots when you type `COLD2`. The current settings will by showed when file [****print-cfg-rp2350.f****](../Tools/print-cfg-rp2350.f)
is included.
