module rst_synchronizer(
    input logic clk,
    input logic async_rst,
    output logic sync_rst
    );
    
    // initializes 2-stage synchronizer to 0
    logic [1:0] ff = 2'b00;
    
    // synchronized reset will be connected to this second flip flop
    assign sync_rst = ff[1];
    
    always_ff @(posedge clk) begin
        // captures asynchronous human input
        ff[0] <= async_rst;
        // captures stabilized output
        ff[1] <= ff[0];
    end
endmodule
