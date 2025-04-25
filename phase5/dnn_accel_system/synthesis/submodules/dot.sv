module dot(input logic clk, input logic rst_n,
           // slave (CPU-facing)
           output logic slave_waitrequest,
           input logic [3:0] slave_address,
           input logic slave_read, output logic [31:0] slave_readdata,
           input logic slave_write, input logic [31:0] slave_writedata,
           // master (memory-facing)
           input logic master_waitrequest,
           output logic [31:0] master_address,
           output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
           output logic master_write, output logic [31:0] master_writedata);

    // your code here

    // Internal registers for addresses and word count
    logic [31:0] weight_matrix_add, activations_vector_byte_add, vector_len, r_weight;
    logic [31:0] r_act, accel, product, curr;  
    // State for reading and writing
    typedef enum logic [3:0] {
        IDLE,
        WAIT_WEIGHT,
        READ_WEIGHT,
        WAIT_ACT,
        READ_ACT,
        CALCULATE,
        DONE
    } state_t;
    state_t state;

    always_comb begin
        master_address = 0;
        master_read = 0;

        case(state)
            READ_WEIGHT: begin
                master_address = weight_matrix_add + (curr << 2);
                master_read = 1;
            end

            READ_ACT: begin
                master_address = activations_vector_byte_add + (curr << 2);
                master_read = 1;
            end


        endcase

    end


    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            weight_matrix_add <= 0;
            activations_vector_byte_add <= 0;
            vector_len <= 0;
            curr <= 0;
            state <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    slave_waitrequest <= 0;
                    if(slave_write) begin
                        slave_waitrequest <= 1;
                        case(slave_address)
                            4'b0000: state <= WAIT_WEIGHT;
                            4'b0010: weight_matrix_add <= slave_writedata;
                            4'b0011: activations_vector_byte_add <= slave_writedata;
                            4'b0101: vector_len <= slave_writedata;
                        endcase
                    end
                end

                WAIT_WEIGHT: begin
                    if(!master_waitrequest) begin
                        state <= READ_WEIGHT;
                    end
                end
                READ_WEIGHT: begin
                    if(master_readdatavalid) begin
                        r_weight <= master_readdata;
                        state <= WAIT_ACT;
                    end
                end

                WAIT_ACT: begin
                    if(!master_waitrequest) begin
                        state <= READ_ACT;
                    end
                end

                READ_ACT: begin
                    if(master_readdatavalid) begin
                        r_act <= master_readdata;
                        state <= CALCULATE;
                    end
                end

                CALCULATE: begin
                    if(master_waitrequest) begin
                        curr <= curr + 1;
                        product <= product + (r_weight * r_act) <<< 16; 
                        if(curr + 1 >= vector_len) begin
                            state <= DONE;
                        end else begin
                            state <= WAIT_WEIGHT;
                        end
                    end
                end

            endcase 
        end

    end

endmodule: dot
