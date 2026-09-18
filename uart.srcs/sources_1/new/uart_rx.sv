module uart_rx(
    input logic clk,
    input logic tick_16x,
    input logic rx,
    input logic rst,
    output logic [7:0] rx_data_out,
    output logic rx_done_tick
    );
    
    logic [1:0] sync_rx;
    logic [3:0] tick_counter;
    logic [2:0] bit_counter;
    logic sample_6, sample_7, sample_8;
    logic data_bit;
    
    assign data_bit = (sample_6 & sample_7) | (sample_6 & sample_8) | (sample_7 & sample_8);
    
    typedef enum logic [1:0] {
        RX_IDLE = 2'b00,
        RX_START = 2'b01,
        RX_DATA = 2'b11,
        RX_STOP = 2'b10
    } uart_rx_state;
    
    uart_rx_state current_state;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            current_state <= RX_IDLE;
            rx_done_tick <= 0;
            rx_data_out <= 0;
            sync_rx <= 2'b11;
            sample_6 <= 0;
            sample_7 <= 0;
            sample_8 <= 0;
            bit_counter <= 0;
            tick_counter <= 0;
        end else begin
            rx_done_tick <= 0;
            sync_rx[0] <= rx;
            sync_rx[1] <= sync_rx[0];
            if (tick_16x) begin
                case (current_state)
                    RX_IDLE: begin
                        tick_counter <= 0;
                        if (sync_rx[1] == 0) begin
                            current_state <= RX_START;
                        end
                    end
                    RX_START: begin
                        tick_counter <= tick_counter + 1;
                        if (tick_counter == 7) begin
                            if (sync_rx[1] != 0) begin
                                current_state <= RX_IDLE;
                            end
                        end else if (tick_counter == 15) begin
                            current_state <= RX_DATA;
                        end
                    end
                    RX_DATA: begin
                        tick_counter <= tick_counter + 1;
                        if (tick_counter == 6) begin
                            sample_6 <= sync_rx[1];
                        end else if (tick_counter == 7) begin
                            sample_7 <= sync_rx[1];
                        end else if (tick_counter == 8) begin
                            sample_8 <= sync_rx[1];
                        end else if (tick_counter == 15) begin
                            rx_data_out <= {data_bit, rx_data_out[7:1]};
                            bit_counter <= bit_counter + 1;
                            if (bit_counter == 7) begin
                                current_state <= RX_STOP;
                                bit_counter <= 0;
                            end
                        end
                    end
                    RX_STOP: begin
                        tick_counter <= tick_counter + 1;
                        if (tick_counter == 15) begin
                            rx_done_tick <= 1;
                            current_state <= RX_IDLE;
                        end
                    end
                endcase
            end
        end
    end
endmodule