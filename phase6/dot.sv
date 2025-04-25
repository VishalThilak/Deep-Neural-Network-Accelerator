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

    // registers to hold variables
    logic [31:0] weights_i; 
    logic [31:0] ifmap_i; 

    logic signed [31:0] weights_i_val; 
    logic signed [31:0] ifmap_i_val; 

    logic [31:0] base_weight_matrix; 
    logic [31:0] base_activations_matrix; 
    logic [31:0] vec_len; 

    logic signed [31:0] dot_prod; //accumlator

    logic [31:0] temp;

    logic [31:0] frac_part_low; 
    logic signed [31:0] frac_part_high; 

    logic flag1, flag2, flag3; 

    logic [31:0] temp2; 

    logic signed [63:0] full_prod; 


    logic signed [15:0] int_w, frac_w; 
    logic signed [15:0] int_ifmap, frac_ifmap; 

    logic signed [31:0] term1, term2, term3, term4;

    typedef enum logic [3:0] {
        FIRST_3,
        IDLE,
        SET_ADDR_W, 
        COOL_W, 
        READ_W, 
        SET_ADDR_A, 
        COOL_A, 
        COMPUTE_BR, 
        READ_A, 
        ASSIGNREAD, 
        GET_TERMS,
        CALCULATE,
        DONE
    } state_t;
    state_t state;


    assign master_write = 0;     // Can set to 0 since never writing to memory in this module
    assign master_writedata = 0; // Can set to 0 since never writing to memory in this module

    /*always block determining if master_read and
      master_write have to be asserted*/
    always_comb begin
        master_read = 1; 
        if(state == DONE) begin
            master_read = 0; 
        end
    end

    /*always block that runs the FSM*/
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
                    end
                    4'b0011: begin
                        base_activations_matrix <= slave_writedata; 
                    end
                    4'b0101: begin
                        vec_len <= slave_writedata; 
                    end

                    4'b0000: begin
                        slave_waitrequest <= 1; 
                        state <= SET_ADDR_W; 
                    end
                    default: state <= FIRST_3; 
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
                if(master_readdatavalid && !master_waitrequest) begin
                    weights_i_val <= master_readdata; 
                    state <= SET_ADDR_A; 
                end
            end

            SET_ADDR_A: begin
                master_address <= base_activations_matrix + (ifmap_i * 4); 
                state <= COOL_A; 
            end

            COOL_A: begin
                state <= READ_A; 
            end

            READ_A: begin
                if(master_readdatavalid && !master_waitrequest) begin
                    ifmap_i_val <= master_readdata; 
                    state <= CALCULATE; 
                end
            end

            CALCULATE: begin
                int_w <= weights_i_val[31:16]; 
                frac_w <= weights_i_val[15:0]; 

                int_ifmap <= ifmap_i_val[31:16]; 
                frac_ifmap <= ifmap_i_val[15:0];                 

                state <= GET_TERMS;
            end

            GET_TERMS: begin
                term1 <= int_w * int_ifmap;                         // Integer * Integer
                term2 <= (int_w * frac_ifmap) >>> 16;               // Integer * Fractional
                term3 <= (frac_w * int_ifmap) >>> 16;               // Fractional * Integer
                term4 <= (frac_w * frac_ifmap) >>> 16;              // Fractional * Fractional
                state <= COMPUTE_BR; 
            end


            COMPUTE_BR: begin
                dot_prod <= dot_prod + ((term1 <<< 16) + term2 + term3 + (term4 >>> 16));

                temp2 <= 32'd10; 
                if(weights_i >= vec_len - 1) begin
                    temp2 <= 32'd15;
                    slave_readdata <= 32'b0000_0000_0000_0001_0000_0000_0000_0000;
                    state <= ASSIGNREAD; 
                end
                else begin
                    state <= SET_ADDR_W; 
                    weights_i <= weights_i + 32'd1; 
                    ifmap_i <= ifmap_i + 32'd1; 
                end
            end

            ASSIGNREAD: begin
                slave_readdata <= dot_prod; 
                state <= DONE; 
                slave_waitrequest <= 0; 
            end

            DONE: begin
                if(slave_read) begin
                    state <= FIRST_3; 
                end

                weights_i <= 0; 
                ifmap_i <= 0; 
                dot_prod <= 0; 
            end
            endcase
        end
    end
    

endmodule: dot