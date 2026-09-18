module rst_synchronizer(
    input logic clk,
    input logic async_rst,
    output logic sync_rst
    );
    
    logic [1:0] ff;
    
    assign sync_rst = ff[1];
    
    initial begin
        ff = 2'b00;
    end
    
    always_ff @(posedge clk) begin
        ff[0] <= async_rst;
        ff[1] <= ff[0];
    end
endmodule
