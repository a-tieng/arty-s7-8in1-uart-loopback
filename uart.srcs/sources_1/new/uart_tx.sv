module uart_tx(
    input logic clk,
    input logic tick_16x,
    input logic [7:0] tx_data_in,
    input logic tx_start,
    input logic rst,
    output logic tx_data_out,
    output logic tx_done_tick,
    output logic tx_busy
    );

    typedef enum logic [1:0] {
        TX_IDLE = 2'b00,
        TX_START = 2'b01,
        TX_DATA = 2'b11,
        TX_STOP = 2'b10
    } uart_tx_state;
    
    logic [3:0] tick_counter;
    logic [3:0] bit_counter;
    logic [7:0] data;
    
    uart_tx_state current_state;
    assign tx_busy = (current_state != TX_IDLE);
    
    always_ff @(posedge clk) begin
        if (rst) begin
            tick_counter <= 0;
            bit_counter <= 0;
            data <= 0;
            current_state <= TX_IDLE;
            tx_data_out <= 1;
        end else begin
            tx_done_tick <= 0;
            if (tick_16x) begin
                case (current_state)
                    TX_IDLE: begin
                        tick_counter <= 0;
                        bit_counter <= 0;
                        tx_data_out <= 1;
                        if (tx_start) begin
                            current_state <= TX_START;
                        end
                    end
                    TX_START: begin
                        tick_counter <= tick_counter + 1;
                        tx_data_out <= 0;
                        if (tick_counter == 0) begin
                            data <= tx_data_in;
                        end else if (tick_counter == 15) begin
                            current_state <= TX_DATA;
                        end
                    end
                    TX_DATA: begin
                        tick_counter <= tick_counter + 1;
                        if (tick_counter == 0) begin
                            tx_data_out <= data[bit_counter];
                            bit_counter <= bit_counter + 1;
                        end
                        if (tick_counter == 15 && bit_counter == 8) begin
                            current_state <= TX_STOP;
                        end
                    end
                    TX_STOP: begin
                        tick_counter <= tick_counter + 1;
                        tx_data_out <= 1;
                        if (tick_counter == 15) begin
                            current_state <= TX_IDLE;
                            tx_done_tick <= 1;
                        end
                    end
                endcase
            end
        end
    end
endmodule