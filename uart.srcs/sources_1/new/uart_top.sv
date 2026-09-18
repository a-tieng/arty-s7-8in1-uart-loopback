module uart_top(
    input logic CLK100MHZ,
    input logic clk_rst,
    input logic uart_txd_in,
    output logic uart_rxd_out
    );
    
    logic tick_16x;
    logic [7:0] data_bus;
    logic rx_done_tick, tx_done_tick;
    logic rst;
    
    logic tx_start_hold;
    logic tx_busy;
    
    always_ff @(posedge CLK100MHZ) begin
        if (rst) begin
            tx_start_hold <= 0;
        end else if (rx_done_tick) begin
            tx_start_hold <= 1;
        end else if (tx_busy) begin
            tx_start_hold <= 0;
        end
    end
    
    baud_generator baud_rate (
        .clk(CLK100MHZ),
        .rst(rst),
        .tick_16x(tick_16x)
    );
    
    uart_rx rx (
        .clk(CLK100MHZ),
        .tick_16x(tick_16x),
        .rx(uart_txd_in),
        .rst(rst),
        .rx_data_out(data_bus),
        .rx_done_tick(rx_done_tick)
    );
    
    uart_tx tx (
        .clk(CLK100MHZ),
        .tick_16x(tick_16x),
        .tx_data_in(data_bus),
        .tx_start(tx_start_hold),
        .rst(rst),
        .tx_data_out(uart_rxd_out),
        .tx_done_tick(tx_done_tick),
        .tx_busy(tx_busy)
    );
    
    rst_synchronizer reset (
        .clk(CLK100MHZ),
        .async_rst(clk_rst),
        .sync_rst(rst)
    );
endmodule