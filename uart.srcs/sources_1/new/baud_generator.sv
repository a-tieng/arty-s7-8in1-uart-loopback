module baud_generator(
    input logic clk,
    input logic rst,
    output logic tick_16x
    );
    parameter SAMPLING_RATE = 100_000_000 / (115_200 * 16);
    logic [5:0] counter = 0;
    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            tick_16x <= 0;
        end
        if (counter != (SAMPLING_RATE - 1)) begin
            counter <= counter + 1;
            tick_16x <= 1'b0;
        end else begin
            counter <= 0;
            tick_16x <= 1'b1;
        end
    end
endmodule
