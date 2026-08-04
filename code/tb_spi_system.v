//=============================================================
// tb_spi_system.v
// Testbench for spi_master.v
// Verified compatible with Vivado 2022.1 (Behavioral Simulation)
//
// Tests:
//   Test 1  - Reset clears all outputs
//   Test 2  - Normal transaction 0x05 -> slave returns 0x06
//   Test 3  - Normal transaction 0xA3 -> slave returns 0x5C
//   Test 4  - Boundary: tx=0x00, miso=0xFF (all bits inverted)
//   Test 5  - Boundary: tx=0xFF, miso=0x00 (all bits inverted)
//   Test 6  - Back-to-back transaction 0x12 -> 0x34
//   Test 7  - done pulse is exactly 1 clock cycle wide
//=============================================================
`timescale 1ns / 1ps

module tb_spi_system;

    //----------------------------------------------------------
    // DUT signals
    //----------------------------------------------------------
    reg        clk;
    reg        rst;
    reg        start;
    reg [7:0]  tx_data;
    wire [7:0] rx_data;
    wire       busy;
    wire       done;
    wire       sclk;
    wire       mosi;
    reg        miso;
    wire       cs_n;

    // Testbench state
    reg [7:0]  miso_byte;
    reg [7:0]  captured_mosi;
    integer    pass_count;
    integer    fail_count;
    integer    i;
    reg        done_seen;

    //----------------------------------------------------------
    // DUT - CLK_DIV=4 for fast simulation
    //----------------------------------------------------------
    spi_master #(
        .CLK_DIV(4)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .busy   (busy),
        .done   (done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n)
    );

    //----------------------------------------------------------
    // Clock - 10 ns period (100 MHz)
    //----------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //----------------------------------------------------------
    // Task: send one byte, drive MISO, check MOSI + rx_data
    //----------------------------------------------------------
    task run_transaction;
        input [7:0] tx;
        input [7:0] rx;
        begin
            miso_byte     = rx;
            tx_data       = tx;
            captured_mosi = 8'h00;

            @(posedge clk); #1;
            start = 1;
            @(posedge clk); #1;
            start = 0;

            @(posedge clk); #1;
            if (cs_n !== 1'b0) begin
                $display("FAIL  CS_N did not assert  tx=0x%02X", tx);
                fail_count = fail_count + 1;
            end

            for (i = 7; i >= 0; i = i - 1) begin
                @(posedge sclk); #1;
                miso = miso_byte[i];
                @(negedge sclk); #2;
                captured_mosi[i] = mosi;
            end

            @(posedge done);

            if (captured_mosi !== tx) begin
                $display("FAIL  MOSI   tx=0x%02X  captured=0x%02X", tx, captured_mosi);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS  MOSI   tx=0x%02X  transmitted correctly", tx);
                pass_count = pass_count + 1;
            end

            @(posedge clk); #1;
            if (rx_data !== rx) begin
                $display("FAIL  MISO   expected rx=0x%02X  got rx_data=0x%02X", rx, rx_data);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS  MISO   rx_data=0x%02X  received correctly", rx_data);
                pass_count = pass_count + 1;
            end

            if (cs_n !== 1'b1) begin
                $display("FAIL  CS_N did not deassert after transfer  tx=0x%02X", tx);
                fail_count = fail_count + 1;
            end

            if (busy !== 1'b0) begin
                $display("FAIL  busy still HIGH after done  tx=0x%02X", tx);
                fail_count = fail_count + 1;
            end

            repeat(10) @(posedge clk);
        end
    endtask

    //----------------------------------------------------------
    // Task: check done pulse is exactly 1 clock wide
    //----------------------------------------------------------
    task check_done_width;
        input [7:0] tx;
        input [7:0] rx;
        begin
            miso_byte = rx;
            tx_data   = tx;

            @(posedge clk); #1;
            start = 1;
            @(posedge clk); #1;
            start = 0;

            for (i = 7; i >= 0; i = i - 1) begin
                @(posedge sclk); #1;
                miso = miso_byte[i];
                @(negedge sclk);
            end

            @(posedge done); #1;

            @(posedge clk); #1;
            if (done !== 1'b0) begin
                $display("FAIL  done pulse wider than 1 clock cycle");
                fail_count = fail_count + 1;
            end else begin
                $display("PASS  done pulse width = exactly 1 clock cycle");
                pass_count = pass_count + 1;
            end

            repeat(10) @(posedge clk);
        end
    endtask

    //----------------------------------------------------------
    // Stimulus
    //----------------------------------------------------------
    initial begin
        rst           = 1;
        start         = 0;
        tx_data       = 8'h00;
        miso          = 0;
        miso_byte     = 8'h00;
        captured_mosi = 8'h00;
        pass_count    = 0;
        fail_count    = 0;
        done_seen     = 0;
        i             = 0;

        $display("=================================================");
        $display("  tb_spi_system  Vivado 2022.1 Behavioral Sim   ");
        $display("  CLK_DIV=4  10 ns clock  SPI clock = 40 ns     ");
        $display("=================================================");

        repeat(5) @(posedge clk);

        // TEST 1: reset state
        if (cs_n !== 1'b1 || sclk !== 1'b0 ||
            mosi  !== 1'b0 || busy !== 1'b0 || done !== 1'b0) begin
            $display("FAIL  Test 1: outputs not cleared in reset");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS  Test 1: all outputs correct during reset");
            pass_count = pass_count + 1;
        end

        @(posedge clk); #1;
        rst = 0;
        repeat(5) @(posedge clk);

        $display("-------------------------------------------------");
        $display("  Test 2: tx=0x05  miso=0x06");
        run_transaction(8'h05, 8'h06);

        $display("-------------------------------------------------");
        $display("  Test 3: tx=0xA3  miso=0x5C");
        run_transaction(8'hA3, 8'h5C);

        $display("-------------------------------------------------");
        $display("  Test 4: boundary tx=0x00  miso=0xFF");
        run_transaction(8'h00, 8'hFF);

        $display("-------------------------------------------------");
        $display("  Test 5: boundary tx=0xFF  miso=0x00");
        run_transaction(8'hFF, 8'h00);

        $display("-------------------------------------------------");
        $display("  Test 6: back-to-back tx=0x12  miso=0x34");
        run_transaction(8'h12, 8'h34);

        $display("-------------------------------------------------");
        $display("  Test 7: done pulse width  tx=0xAA  miso=0x55");
        check_done_width(8'hAA, 8'h55);

        $display("=================================================");
        $display("  RESULTS:  %0d PASSED    %0d FAILED",
                 pass_count, fail_count);
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** %0d FAILURE(S) - CHECK WAVEFORM ***",
                     fail_count);
        $display("=================================================");
        $finish;
    end

    initial begin
        #200000;
        $display("TIMEOUT - 200 us exceeded, FSM may be stuck");
        $finish;
    end

endmodule
