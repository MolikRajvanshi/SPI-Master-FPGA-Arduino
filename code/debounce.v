//============================================================
// debounce.v
// 2-stage synchronizer + stable-counter button debouncer.
// Generates a single 1-cycle pulse on the rising edge of the
// debounced signal.
//
// DEBOUNCE_CYCLES : consecutive clock cycles input must stay
//   stable before being accepted.
//   1,000,000 = 10 ms at 100 MHz (comfortable for any button).
//============================================================

module debounce #(
    parameter DEBOUNCE_CYCLES = 1_000_000
)(
    input  wire clk,
    input  wire rst,
    input  wire btn_in,       // raw (async) button input
    output reg  pulse_out     // single-cycle pulse on stable rising edge
);

    // Two-stage synchronizer (removes metastability)
    reg btn_s0, btn_s1;

    // Debounce state
    reg [19:0] cnt;
    reg        btn_db;       // debounced stable level
    reg        btn_prev;     // previous stable level (edge detect)

    always @(posedge clk) begin
        if (rst) begin
            btn_s0    <= 0;
            btn_s1    <= 0;
            cnt       <= 0;
            btn_db    <= 0;
            btn_prev  <= 0;
            pulse_out <= 0;
        end else begin
            btn_s0 <= btn_in;
            btn_s1 <= btn_s0;

            pulse_out <= 0;
            btn_prev  <= btn_db;

            if (btn_s1 == btn_db) begin
                cnt <= 0;               // input matches stable level - reset
            end else begin
                if (cnt == DEBOUNCE_CYCLES - 1) begin
                    btn_db <= btn_s1;   // held long enough - accept
                    cnt    <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end

            // Rising-edge detect
            if (btn_db && !btn_prev)
                pulse_out <= 1;
        end
    end

endmodule
