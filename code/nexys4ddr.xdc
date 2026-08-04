##============================================================
## nexys4ddr.xdc
## Vivado pin/timing constraints -- Nexys 4 DDR
## Device: XC7A100T-1CSG324C
## Project: FPGA <-> Arduino SPI demo
##============================================================

##------------------------------------------------------------
## 100 MHz system clock
##------------------------------------------------------------
set_property PACKAGE_PIN E3        [get_ports clk]
set_property IOSTANDARD  LVCMOS33  [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

##------------------------------------------------------------
## Buttons
##   BTNC (centre) -> rst        (synchronous reset)
##   BTND (down)   -> btn_send   (trigger SPI transfer)
##------------------------------------------------------------
set_property PACKAGE_PIN N17       [get_ports rst]
set_property IOSTANDARD  LVCMOS33  [get_ports rst]

set_property PACKAGE_PIN P18       [get_ports btn_send]
set_property IOSTANDARD  LVCMOS33  [get_ports btn_send]

##------------------------------------------------------------
## Switches SW[7:0]  -- byte to send to Arduino
##------------------------------------------------------------
set_property PACKAGE_PIN J15       [get_ports {sw[0]}]
set_property PACKAGE_PIN L16       [get_ports {sw[1]}]
set_property PACKAGE_PIN M13       [get_ports {sw[2]}]
set_property PACKAGE_PIN R15       [get_ports {sw[3]}]
set_property PACKAGE_PIN R17       [get_ports {sw[4]}]
set_property PACKAGE_PIN T18       [get_ports {sw[5]}]
set_property PACKAGE_PIN U18       [get_ports {sw[6]}]
set_property PACKAGE_PIN R13       [get_ports {sw[7]}]
set_property IOSTANDARD  LVCMOS33  [get_ports {sw[*]}]

##------------------------------------------------------------
## LEDs [15:0]
##------------------------------------------------------------
set_property PACKAGE_PIN H17       [get_ports {led[0]}]
set_property PACKAGE_PIN K15       [get_ports {led[1]}]
set_property PACKAGE_PIN J13       [get_ports {led[2]}]
set_property PACKAGE_PIN N14       [get_ports {led[3]}]
set_property PACKAGE_PIN R18       [get_ports {led[4]}]
set_property PACKAGE_PIN V17       [get_ports {led[5]}]
set_property PACKAGE_PIN U17       [get_ports {led[6]}]
set_property PACKAGE_PIN U16       [get_ports {led[7]}]
set_property PACKAGE_PIN V16       [get_ports {led[8]}]
set_property PACKAGE_PIN T15       [get_ports {led[9]}]
set_property PACKAGE_PIN U14       [get_ports {led[10]}]
set_property PACKAGE_PIN T16       [get_ports {led[11]}]
set_property PACKAGE_PIN V15       [get_ports {led[12]}]
set_property PACKAGE_PIN V14       [get_ports {led[13]}]
set_property PACKAGE_PIN V12       [get_ports {led[14]}]
set_property PACKAGE_PIN V11       [get_ports {led[15]}]
set_property IOSTANDARD  LVCMOS33  [get_ports {led[*]}]

##------------------------------------------------------------
## Pmod JA -- SPI bus to Arduino
##------------------------------------------------------------
set_property PACKAGE_PIN C17       [get_ports ja_cs_n]
set_property PACKAGE_PIN D18       [get_ports ja_mosi]
set_property PACKAGE_PIN E18       [get_ports ja_miso]
set_property PACKAGE_PIN G17       [get_ports ja_sclk]
set_property IOSTANDARD  LVCMOS33  [get_ports ja_cs_n]
set_property IOSTANDARD  LVCMOS33  [get_ports ja_mosi]
set_property IOSTANDARD  LVCMOS33  [get_ports ja_miso]
set_property IOSTANDARD  LVCMOS33  [get_ports ja_sclk]
