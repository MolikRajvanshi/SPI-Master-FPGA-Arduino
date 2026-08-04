# Sources, References and Tools Used

> A comprehensive list of all resources referenced during the design, implementation, simulation, and hardware verification of the SPI Master FPGA project.

---

## Textbooks and Standards

| # | Source | How It Was Used |
|---|---|---|
| 1 | **IEEE Std 1364-2001** — *Standard Verilog Hardware Description Language* | Primary language specification for synthesisable Verilog design (`top.v`, `spi_master.v`, `debounce.v`) and behavioural simulation (`tb_spi_system.v`). |
| 2 | **Pong P. Chu** — *RTL Hardware Design Using Verilog*, Wiley-IEEE Press, 2006 | Reference for finite state machine (FSM) state encoding, shift register architectures, synchronous clock division, and debouncer design. |
| 3 | **M. M. Mano and M. D. Ciletti** — *Digital Design: With an Introduction to Verilog HDL*, 5th ed., Pearson, 2013 | Referenced for foundational digital design concepts including SPI bus topologies, shift registers, edge detection, and setup/hold timing constraints. |
| 4 | **P. J. Ashenden** — *The Student's Guide to VHDL / Verilog*, Morgan Kaufmann | Reference for testbench verification methodologies, self-checking assertions, and event-driven simulation constructs. |

---

## Hardware Documentation

| # | Source | Link | How It Was Used |
|---|---|---|---|
| 5 | **Digilent Inc.** — *Nexys 4 DDR Reference Manual* | [reference.digilentinc.com/nexys4-ddr](https://reference.digilentinc.com/nexys4-ddr) | Pin mapping for Pmod JA expansion header, 100 MHz oscillator (pin E3), push buttons (`BTNC`, `BTND`), DIP switches (`SW0`-`SW7`), and LEDs (`LED0`-`LED15`). |
| 6 | **Xilinx Inc.** — *7 Series FPGAs Data Sheet: Overview (DS180)* | [xilinx.com/.../ds180](https://www.xilinx.com/support/documentation/data_sheets/ds180_7Series_Overview.pdf) | Specifications for the Artix-7 XC7A100T-1CSG324C FPGA: LUT count (63,400), Flip-Flop count (126,800), max I/O toggle rates, and thermal parameters. |
| 7 | **Microchip / Atmel** — *ATmega328P 8-bit AVR Microcontroller Datasheet* | [microchip.com](https://www.microchip.com) | Hardware SPI slave register configuration (`SPCR`, `SPSR`, `SPDR`), interrupt vector `ISR(SPI_STC_vect)`, and input voltage thresholds ($V_{IH} = 2.0\text{V}$). |

---

## Software and EDA Tools

| # | Tool | Version | Purpose |
|---|---|---|---|
| 8 | **Xilinx Vivado Design Suite** | 2022.1 | RTL synthesis, implementation (place & route), bitstream generation, timing analysis, and hardware programming over USB-JTAG. |
| 9 | **Vivado Simulator (xsim)** | Integrated in Vivado 2022.1 | Behavioural simulation of `tb_spi_system.v` with waveform visual inspection. |
| 10 | **Arduino IDE** | 2.x | Writing, compiling (AVR-GCC), and uploading the C++ SPI slave firmware to Arduino Uno, plus live monitoring via Serial Monitor (115200 baud). |

---

## Xilinx Application Notes and User Guides

| # | Document | How It Was Used |
|---|---|---|
| 11 | **UG903** — *Vivado Design Suite User Guide: Using Constraints*, Xilinx | Referenced for XDC constraint formatting: `set_property`, `create_clock`, `get_ports`, `PACKAGE_PIN`, and `IOSTANDARD` LVCMOS33 parameters. |
| 12 | **UG901** — *Vivado Design Suite User Guide: Synthesis*, Xilinx | Guidelines on FSM state encoding inference, synchronizer flip-flop inference, and shift register primitives. |
| 13 | **UG906** — *Vivado Design Suite User Guide: Design Analysis and Closure Techniques*, Xilinx | Interpreting post-implementation timing reports (Worst Negative Slack WNS, Total Negative Slack TNS, setup/hold slack). |

---

## Technical Design Concepts

| Concept | Primary Reference | Application in This Project |
|---|---|---|
| **SPI Mode 0 Protocol** | Motorola / NXP SPI Specification | Full-duplex MSB-first serial transfer; MOSI updated on negedge SCLK, MISO sampled on posedge SCLK; `CS_N` active LOW. |
| **Metastability Protection** | Pong P. Chu, Ch. 4 | 2-stage flip-flop synchronizer (`sync_0`, `sync_1`) on asynchronous push-button input. |
| **Stable-Counter Debouncing** | Pong P. Chu, Ch. 4 | 20-bit counter requiring 10 ms (1,000,000 clock cycles at 100 MHz) of identical input level before registering button state. |
| **Voltage Level Division** | Microchip ATmega328P Datasheet | 1 kΩ / 2 kΩ resistor voltage divider scaling 5.0V Arduino MISO output down to 3.33V for safe FPGA pin reception. |
| **Output Data Persistence** | Standard RTL Register Practice | `rx_latch` register in `top.v` updated on rising edge of `done` to maintain LED display between transfers. |

---

## Quick Reference Links

- [Nexys 4 DDR Reference Manual](https://reference.digilentinc.com/nexys4-ddr)
- [Artix-7 FPGA Data Sheet (DS180)](https://www.xilinx.com/support/documentation/data_sheets/ds180_7Series_Overview.pdf)
- [ATmega328P Microcontroller Datasheet](https://www.microchip.com/en-us/product/ATmega328P)
- [Vivado Constraints Guide (UG903)](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints)
- [Vivado Synthesis Guide (UG901)](https://docs.amd.com/r/en-US/ug901-vivado-synthesis)
- [Arduino IDE Download](https://www.arduino.cc/en/software)
- [Xilinx Vivado Download](https://www.xilinx.com/support/download.html)

---

> **Note:** All digital hardware logic (FSM, clock divider, debouncer, shift registers) was written manually in Verilog HDL. No third-party IP cores or auto-generated logic blocks were used in this design.
