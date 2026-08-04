//============================================================
// spi_master.v
// SPI Mode 0 (CPOL=0, CPHA=0) - 8-bit full-duplex master
// Target : Nexys 4 DDR  (Artix-7, 100 MHz system clock)
// Slave  : Arduino Uno  (SPI hardware slave, Mode 0)
//
// SPI clock = sys_clk / (2 * CLK_DIV)
// Default   : CLK_DIV = 50  -> 1 MHz SPI clock
//
// Full-duplex behaviour (each transaction):
//   FPGA sends  : tx_data  (from SW[7:0])   -> Arduino MOSI
//   Arduino sends back (received+1)         -> FPGA   MISO
//   FPGA latches the response into rx_data when done=1
//
// Timing (Mode 0):
//   CS_N  falls before first SCK edge
//   MOSI  is stable before every rising SCK edge (master drives on falling)
//   MISO  is sampled on every rising SCK edge
//   CS_N  rises after the 8th falling SCK edge
//============================================================

module spi_master #(
    parameter CLK_DIV = 50      // half-period tick count (1..255)
)(
    input  wire       clk,
    input  wire       rst,      // synchronous active-high reset
    // Control
    input  wire       start,    // single-cycle pulse: begin transfer
    input  wire [7:0] tx_data,  // byte to transmit (MSB first)
    output reg  [7:0] rx_data,  // byte received from Arduino (valid when done=1)
    output reg        busy,     // high throughout the transfer
    output reg        done,     // one-cycle pulse: transfer finished, rx_data valid
    // SPI bus pins (go to Pmod JA)
    output reg        sclk,
    output reg        mosi,
    input  wire       miso,
    output reg        cs_n      // active-low chip-select
);

    localparam IDLE     = 2'd0;
    localparam TRANSFER = 2'd1;
    localparam FINISH   = 2'd2;

    reg [1:0] state;
    reg [7:0] clk_cnt;   // half-period counter  (0 .. CLK_DIV-1)
    reg [2:0] bit_cnt;   // bit index within the current byte (0..7)
    reg       clk_phase; // 0 = about to generate rising edge
    reg [7:0] shift_tx;  // TX shift register (loaded from tx_data)
    reg [7:0] shift_rx;  // RX shift register (builds received byte)

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_cnt   <= 0;
            bit_cnt   <= 0;
            clk_phase <= 0;
            shift_tx  <= 0;
            shift_rx  <= 0;
            sclk      <= 0;
            mosi      <= 0;
            cs_n      <= 1;
            busy      <= 0;
            done      <= 0;
            rx_data   <= 0;
        end else begin
            done <= 0;  // pulse for one cycle only

            case (state)

                //---------------------------------------------
                IDLE: begin
                    sclk      <= 0;
                    cs_n      <= 1;
                    busy      <= 0;
                    clk_cnt   <= 0;
                    bit_cnt   <= 0;
                    clk_phase <= 0;

                    if (start) begin
                        shift_tx <= tx_data;
                        mosi     <= tx_data[7]; // MSB on MOSI before first rising edge
                        cs_n     <= 0;          // assert CS_N
                        busy     <= 1;
                        state    <= TRANSFER;
                    end
                end

                //---------------------------------------------
                TRANSFER: begin
                    if (clk_cnt < CLK_DIV - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;

                        if (!clk_phase) begin
                            // ---- Rising SCK edge ----
                            sclk      <= 1;
                            shift_rx  <= {shift_rx[6:0], miso};
                            clk_phase <= 1;

                        end else begin
                            // ---- Falling SCK edge ----
                            sclk <= 0;

                            if (bit_cnt == 3'd7) begin
                                // All 8 bits done
                                state <= FINISH;
                            end else begin
                                bit_cnt   <= bit_cnt + 1;
                                shift_tx  <= {shift_tx[6:0], 1'b0};
                                mosi      <= shift_tx[6];
                                clk_phase <= 0;
                            end
                        end
                    end
                end

                //---------------------------------------------
                FINISH: begin
                    cs_n    <= 1;           // deassert CS_N
                    sclk    <= 0;
                    busy    <= 0;
                    done    <= 1;           // one-cycle pulse
                    rx_data <= shift_rx;    // latch received byte
                    state   <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
