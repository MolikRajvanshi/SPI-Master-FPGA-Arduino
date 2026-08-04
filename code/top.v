//============================================================
// top.v - Top-level wrapper: FPGA <-> Arduino SPI demo
// Target  : Nexys 4 DDR (Artix-7 XC7A100T, 100 MHz)
//
// USER STEPS:
//   1. Set SW[7:0] to the byte you want to send to Arduino.
//   2. Press BTND once.
//   3. Arduino receives the byte, prints it on Serial Monitor,
//      then sends back (received + 1).
//   4. FPGA latches the returned byte -> shown on LED[7:0].
//      LED[15] lights while the SPI transfer is in progress.
//
// WIRING  (Pmod JA -> Arduino Uno):
//   JA pin 1 (C17)  CS_N  -> Arduino pin 10 (SS)       - direct
//   JA pin 2 (D18)  MOSI  -> Arduino pin 11 (MOSI)     - direct
//   JA pin 3 (E18)  MISO  <- Arduino pin 12 (MISO)     - !! LEVEL SHIFT !!
//   JA pin 4 (G17)  SCLK  -> Arduino pin 13 (SCK)      - direct
//   JA GND          GND   -> Arduino GND                - must connect
//
// MISO level-shift (5 V -> 3.3 V):
//   Arduino pin 12 -> [1 kOhm] -> node -> [2 kOhm] -> GND
//   node connects to FPGA JA pin 3
//============================================================

module top (
    input  wire        clk,         // 100 MHz  (E3)
    input  wire        rst,         // BTNC - synchronous reset
    input  wire        btn_send,    // BTND - trigger one SPI transfer
    input  wire [7:0]  sw,          // SW[7:0] - byte to send
    output wire [15:0] led,         // LED[7:0] = last RX byte,  LED[15] = busy
    // Pmod JA
    output wire        ja_cs_n,
    output wire        ja_sclk,
    output wire        ja_mosi,
    input  wire        ja_miso
);

    //----------------------------------------------------------
    // 1. Debounce BTND -> single-cycle start pulse
    //----------------------------------------------------------
    wire start_pulse;

    debounce #(
        .DEBOUNCE_CYCLES(1_000_000)   // 10 ms at 100 MHz
    ) u_debounce (
        .clk      (clk),
        .rst      (rst),
        .btn_in   (btn_send),
        .pulse_out(start_pulse)
    );

    //----------------------------------------------------------
    // 2. SPI master
    //----------------------------------------------------------
    wire [7:0] rx_data;
    wire       busy, done;

    spi_master #(
        .CLK_DIV(50)                  // SPI clock = 1 MHz  (100 MHz / 100)
    ) u_spi (
        .clk     (clk),
        .rst     (rst),
        .start   (start_pulse),
        .tx_data (sw),
        .rx_data (rx_data),
        .busy    (busy),
        .done    (done),
        .sclk    (ja_sclk),
        .mosi    (ja_mosi),
        .miso    (ja_miso),
        .cs_n    (ja_cs_n)
    );

    //----------------------------------------------------------
    // 3. Latch received byte from Arduino
    //----------------------------------------------------------
    reg [7:0] rx_latch;

    always @(posedge clk) begin
        if (rst)
            rx_latch <= 8'h00;
        else if (done)
            rx_latch <= rx_data;
    end

    //----------------------------------------------------------
    // 4. LED output
    //----------------------------------------------------------
    assign led[7:0]  = rx_latch;
    assign led[14:8] = 7'b000_0000;
    assign led[15]   = busy;

endmodule
