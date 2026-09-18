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
    
    // 4-bit counter to track 16x oversampling
    logic [3:0] tick_counter;
    
    //  3-bit counter to track total bits already transmitted
    logic [3:0] bit_counter;
    
    // data to transmit
    logic [7:0] data;
    
    // fsm states
    typedef enum logic [1:0] {
        // no data to be transmitted
        TX_IDLE = 2'b00,
        
        // initializes everything for data transmission
        TX_START = 2'b01,
        
        // data transmittion
        TX_DATA = 2'b11,
        
        // resets everything, keeps output high to indicate no data, outputs tx done tick
        TX_STOP = 2'b10
    } uart_tx_state;
    
    uart_tx_state current_state;
    
    assign tx_busy = (current_state != TX_IDLE);
    
    always_ff @(posedge clk) begin
        if (rst) begin
            // resets everything to default
            tick_counter <= 0;
            bit_counter <= 0;
            data <= 0;
            current_state <= TX_IDLE;
            
            // setting high after transmission means no data is being trasmitted
            tx_data_out <= 1;
        end else begin
            // default assignment ensures tx done tick is high for a single clock cycle (10ns)
            tx_done_tick <= 0;
            
            if (current_state == TX_IDLE) begin
                tick_counter <= 0;
                bit_counter <= 0;
                   
                // set high to indicate no current data transmitting
                tx_data_out <= 1;
     
                // tx start tells tx module to begin transmission data
                if (tx_start) begin
                    current_state <= TX_START;
                    
                    // locks data
                    data <= tx_data_in;
                end
            end
            
            // fsm state logic and data transmission based on baud rate
            if (tick_16x) begin
                case (current_state)
                    TX_START: begin
                        tick_counter <= tick_counter + 1;
                        tx_data_out <= 0;
                        if (tick_counter == 15) begin
                            current_state <= TX_DATA;
                        end
                    end
                    TX_DATA: begin
                        tick_counter <= tick_counter + 1;
                        if (tick_counter == 0) begin
                            // lsb out first
                            tx_data_out <= data[0];
                            
                            bit_counter <= bit_counter + 1;
                            
                            // right shifts all data
                            data <= {1'b0, data[7:1]};
                        end else if (tick_counter == 15 && bit_counter == 8) begin
                            // once eight bits of data transmitted, its done
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
                    default: ; // TX_IDLE tracked outside of baud rate
                endcase
            end
        end
    end
endmodule