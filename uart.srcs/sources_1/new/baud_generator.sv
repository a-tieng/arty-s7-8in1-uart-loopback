module baud_generator(
    input logic clk,
    input logic rst,
    output logic tick_16x
    );

    // calculates 115_200 baud rate with 16x oversampling. this is about 54 clock cycles per tick
    parameter SAMPLING_RATE = 100_000_000 / (115_200 * 16);

    // 6-bit counter to hold counter states (0-53)
    logic [5:0] counter = 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            // synchronous reset clears the counter and ticks
            counter <= 0;
            tick_16x <= 0;
        end else if (counter != (SAMPLING_RATE - 1)) begin
            // increment counter and hold tick output low
            counter <= counter + 1;
            tick_16x <= 1'b0;
        end else begin
            // 54 total clock cycles (0-53) have passed
            counter <= 0;
            tick_16x <= 1'b1;
        end
    end
endmodule
