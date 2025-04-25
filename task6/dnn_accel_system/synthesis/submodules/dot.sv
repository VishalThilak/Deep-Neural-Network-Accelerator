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
    logic [31:0] weights_i; 
    logic [31:0] ifmap_i; 

    logic [31:0] weights_i_val; 
    logic [31:0] ifmap_i_val; 

    logic [31:0] base_weight_matrix; 
    logic [31:0] base_activations_matrix; 
    logic [31:0] vec_len; 

    logic [31:0] dot_prod; 

    logic [31:0] temp;

    logic [31:0] frac_part_low; 
    logic [31:0] frac_part_high; 

    logic flag1, flag2, flag3; 

    typedef enum logic [3:0] {
        FIRST_3,
        IDLE,
        SET_ADDR_W, 
        COOL_W, 
        READ_W, 
        SET_ADDR_A, 
        COOL_A, 
        READ_A,
        COMPUTE_BR, 
        WAIT_PROD,
        ASSIGNREAD, 
        DONE
    } state_t;
    state_t state;


    assign master_write = 0;     // Can set to 0 since never writing to memory in this module
    assign master_writedata = 0; // Can set to 0 since never writing to memory in this module

    // assign temp = (weights_i_val * ifmap_i_val);

    always_comb begin
        master_read = 0; 
        if(state == READ_W || state == READ_A) begin
            master_read = 1; 
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            slave_waitrequest <= 1; 
            weights_i <= 0; 
            ifmap_i <= 0; 
            vec_len <= 0; 
            base_weight_matrix <= 0; 
            base_activations_matrix <= 0; 
            vec_len <= 0; 
            flag1 <= 0; 
            flag2 <= 0; 
            flag3 <= 0; 
            state <= FIRST_3; 
            dot_prod <= 0; 
        end
        else begin
            case(state) 
            FIRST_3: begin
                slave_waitrequest <= 0; 
                if(slave_write) begin
                    case(slave_address) 
                    4'b0010: begin
                        base_weight_matrix <= slave_writedata; 
                        // flag1 <= 1; 
                    end
                    4'b0011: begin
                        base_activations_matrix <= slave_writedata; 
                        // flag2 <= 1; 
                    end
                    4'b0101: begin
                        vec_len <= slave_writedata; 
                        // state <= IDLE; 
                        // flag3 <= 1; 
                    end

                    4'b0000: begin
                        slave_waitrequest <= 1; 
                        state <= SET_ADDR_W; 
                    end
                    default: state <= FIRST_3; 
                    endcase
                end
                // if(flag1 && flag2 && flag3) begin
                //     state <= IDLE; 
                // end
            end

            IDLE: begin
                weights_i <= 0; 
                ifmap_i <= 0; 
                
                slave_waitrequest <= 0; 
                if (slave_write) begin
                    case (slave_address)
                        4'b0000: begin
                            slave_waitrequest <= 1; 
                            state <= SET_ADDR_W; 
                        end
                        default: state <= IDLE;  
                    endcase
                end
            end

            SET_ADDR_W: begin
                slave_waitrequest <= 1; 
                master_address <= base_weight_matrix + (weights_i * 4); 
                state <= COOL_W; 
            end

            COOL_W: begin
                state <= READ_W; 
            end

            READ_W: begin
                // slave_waitrequest <= 0; 
                if(master_readdatavalid && !master_waitrequest) begin
                    weights_i_val <= master_readdata; 
                    state <= SET_ADDR_A; 
                end
            end

            SET_ADDR_A: begin
                // slave_waitrequest <= 0; 
                master_address <= base_activations_matrix + (ifmap_i * 4); 
                state <= COOL_A; 
            end

            COOL_A: begin
                state <= READ_A; 
            end

            READ_A: begin
                if(master_readdatavalid && !master_waitrequest) begin
                    ifmap_i_val <= master_readdata; 
                    state <= COMPUTE_BR; 
                end
            end

            COMPUTE_BR: begin
                frac_part_low <= weights_i_val[15:0] * ifmap_i_val[15:0]; 
                frac_part_high <= weights_i_val[31:16] * ifmap_i_val[31:16]; 
                // dot_prod <= {frac_part_high[15:0], frac_part_low[31:16]};
                dot_prod <= 10;
                
                // dot_prod <= temp; 
                // temp <= {frac_part_high << 16}; 
                // temp <= temp + frac_part_low;
                // dot_prod <= dot_prod + temp; 
                // dot_prod <= dot_prod + (frac_part >> 16);
                // dot_prod <= dot_prod + (weights_i_val * ifmap_i_val) ; 

                // dot_prod <= dot_prod + ((weights_i_val * ifmap_i_val) >> 16); 
                
                // dot_prod <= temp >> 16;
                // dot_prod <= dot_prod + temp[15:0]; 
                // dot_prod <= dot_prod + 1; 
                // slave_readdata <= 32'b1;
                if(weights_i >= vec_len) begin
                    // slave_readdata <= dot_prod; 
                    // slave_readdata <= 32'b0000_0000_0000_0001_0000_0000_0000_0000;
                    // slave_readdata <= 32'b1;
                    // state <= WRITE; 
                    state <= WAIT_PROD; 
                    // state <= DONE; 
                    slave_waitrequest <= 0;
                end
                else begin
                    state <= SET_ADDR_W; 
                    weights_i <= weights_i + 1; 
                    ifmap_i <= ifmap_i + 1; 
                end
            end

            WAIT_PROD: begin
                state <= ASSIGNREAD;
            end

            ASSIGNREAD: begin
                slave_readdata <= 10; 
                state <= DONE; 
                slave_waitrequest <= 0; 
            end

            DONE: begin
                slave_waitrequest <= 0; 

                // state <= FIRST_3; 
                if(slave_read) begin
                    state <= FIRST_3; 
                end

                weights_i <= 0; 
                ifmap_i <= 0; 
                // vec_len <= 0; 
                // base_weight_matrix <= 0; 
                // base_activations_matrix <= 0; 
                // vec_len <= 0; 
                // flag1 <= 0; 
                // flag2 <= 0; 
                // flag3 <= 0; 
                // state <= FIRST_3; 
                // dot_prod <= 0; 
            end
            endcase
        end
    end
    

endmodule: dot



// module dot(input logic clk, input logic rst_n,
//            // slave (CPU-facing)
//            output logic slave_waitrequest,
//            input logic [3:0] slave_address,
//            input logic slave_read, output logic [31:0] slave_readdata,
//            input logic slave_write, input logic [31:0] slave_writedata,
//            // master (memory-facing)
//            input logic master_waitrequest,
//            output logic [31:0] master_address,
//            output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
//            output logic master_write, output logic [31:0] master_writedata);

//     // your code here

//     // Internal registers for addresses and word count
//     logic [31:0] weight_matrix_add, activations_vector_byte_add, vector_len, r_weight;
//     logic [31:0] r_act, accel, product, curr;  
//         logic flag1, flag2, flag3; 
//     // State for reading and writing
//     typedef enum logic [3:0] {
//         FIRST_3,
//         IDLE,
//         SET_ADR1,
//         READ_WEIGHT,
//         SET_ADDR2,
//         READ_ACT,
//         CALCULATE,
//         WRITE,
//         DONE
//     } state_t;
//     state_t state;

//     always_comb begin
//         master_address = 0;
//         master_read = 0;
//         slave_waitrequest = 1;
//         master_write = 0;

//         case(state)
//             FIRST_3: begin
//                 slave_waitrequest = 0;
//             end

//             IDLE: begin
//                 slave_waitrequest = 0;
//                 if (slave_write) begin
//                     case (slave_address)
//                         4'b0000: begin
//                             slave_waitrequest = 1; 
//                         end
//                     endcase
//                 end
//             end

//             SET_ADR1: begin
//                 master_address = weight_matrix_add + (curr * 4);
//                 master_read = 1;
//             end

//             SET_ADDR2: begin
//                 master_address = activations_vector_byte_add + (curr * 4);
//                 master_read = 1;
//             end

//             WRITE: begin
//                 master_address = 0;
//                 master_writedata = product;
//                 master_write = 1;
//             end

//             DONE: begin
//                 slave_waitrequest = 0;
//             end
//         endcase

//     end


//     always_ff @(posedge clk or negedge rst_n) begin
//         if(~rst_n)begin
//             weight_matrix_add <= 0;
//             activations_vector_byte_add <= 0;
//             vector_len <= 0;
//             curr <= 0;
//             state <= FIRST_3;
//             flag1 <= 0;
//             flag2 <= 0;
//             flag3 <= 0;
//         end else begin
//             case(state)
//                 FIRST_3: begin
//                     if(slave_write) begin
//                         case (slave_address)
//                             4'b0010: begin
//                                 weight_matrix_add <= slave_writedata;
//                                 flag1 <= 1; 
//                             end
//                             4'b0011: begin
//                                 activations_vector_byte_add <= slave_writedata;
//                                 flag2 <= 1; 
//                             end
//                             4'b0101: begin
//                                 vector_len <= slave_writedata;
//                                 flag3 <= 1; 
//                             end
//                             default: state <= FIRST_3; 
//                         endcase
//                     end
//                     if(flag1 && flag2 && flag3) begin
//                         state <= IDLE; 
//                     end
//                 end

//                 IDLE: begin
//                     if(slave_write) begin
//                         slave_waitrequest <= 1;
//                         case(slave_address)
//                             4'b0000: state <= SET_ADR1;
//                         endcase
//                     end
//                 end

//                 SET_ADR1: begin
//                     state <= READ_WEIGHT;
//                 end

//                 READ_WEIGHT: begin
//                     if(master_readdatavalid && !master_readdatavalid) begin
//                         r_weight <= master_readdata;
//                         state <= SET_ADDR2;
//                     end
//                 end

//                 SET_ADDR2: begin
//                     state <= READ_ACT;
//                 end

//                 READ_ACT: begin
//                     if(master_readdatavalid && !master_readdatavalid) begin
//                         r_act <= master_readdata;
//                         state <= CALCULATE;
//                     end
//                 end

//                 CALCULATE: begin
//                     curr <= curr + 1;
//                     product <= product + (r_weight * r_act) <<< 16; 
//                     if(curr + 1 >= vector_len) begin
//                         state <= WRITE;
//                     end else begin
//                         state <= SET_ADR1;
//                     end
//                 end

//                 WRITE: begin
//                     state <= DONE;
//                 end


//             endcase 
//         end

//     end

// endmodule: dot


// 0000_0000_0000_0001_0110_0000_0000_0000