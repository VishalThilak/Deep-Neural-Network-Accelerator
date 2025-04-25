module wordcopy(
    input logic clk, input logic rst_n,
    // slave (CPU-facing)
    output logic slave_waitrequest,
    input logic [3:0] slave_address,
    input logic slave_read, output logic [31:0] slave_readdata,
    input logic slave_write, input logic [31:0] slave_writedata,
    // master (SDRAM-facing)
    input logic master_waitrequest,
    output logic [31:0] master_address,
    output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
    output logic master_write, output logic [31:0] master_writedata
);

    // Internal registers for addresses and word count
    logic [31:0] base_dest_address;
    logic [31:0] base_src_address;
    logic [31:0] word_count;

    logic [31:0] current_word;
    logic [31:0] read_data;

    // State for reading and writing
    typedef enum logic [3:0] {
        FIRST_3,
        SET_ADDR,
        COOL, 
        IDLE,
        READ,
        WRITE,
        ASSIGNW,
        DONE
    } state_t;
    state_t state;

    // Assigning default values
    logic flag1, flag2, flag3; 

    always_comb begin
        master_read = 0; 
        master_write = 0; 
        // master_writedata = 0; 

        // master_address = 0; 
        // read_data = 0; 

        if(state == READ) begin
            master_read = 1; 
        end
        if(state == WRITE) begin
            // master_writedata = read_data; 
            // master_writedata = 50; 
            master_write = 1; 
        end

    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // Reset all internal states and registers
            current_word <= 0;
            base_dest_address <= 0;
            base_src_address <= 0;
            word_count <= 0;
            state <= FIRST_3;
            read_data <= 0;
            slave_waitrequest <= 1; 
            flag1 <= 0;
            flag2 <= 0;
            flag3 <= 0;
        end else begin
            case (state)
                FIRST_3: begin
                    slave_waitrequest <= 0; 
                    if(slave_write) begin
                        case (slave_address)
                            4'b0001: begin
                                base_dest_address <= slave_writedata;
                                flag1 <= 1; 
                            end
                            4'b0010: begin
                                base_src_address <= slave_writedata;
                                flag2 <= 1; 
                            end
                            4'b0011: begin
                                word_count <= slave_writedata;
                                flag3 <= 1; 
                            end
                            default: state <= FIRST_3; 
                        endcase
                    end
                    if(flag1 && flag2 && flag3) begin
                        state <= IDLE; 
                    end
                end
                IDLE: begin
                    current_word <= 0; 
                    slave_waitrequest <= 0; 
                    if (slave_write) begin
                        case (slave_address)
                            4'b0000: begin
                                slave_waitrequest <= 1; 
                                state <= SET_ADDR; 
                            end
                            default: state <= IDLE;  
                        endcase
                    end
                end
                SET_ADDR: begin
                    slave_waitrequest <= 1; 
                    master_address <= base_src_address + (current_word * 4);  
                    // state <= READ; 
                    state <= COOL; 
                end

                COOL: begin
                    state <= READ; 
                end

                READ: begin
                    if (master_readdatavalid && !master_waitrequest) begin
                    // if (master_readdatavalid) begin
                        read_data <= master_readdata;
                        // state <= WRITE;
                        state <= ASSIGNW; 
                    end
                end

                ASSIGNW: begin
                    master_address <= base_dest_address + (current_word * 4);
                    master_writedata <= read_data; 
                    // state <= WRITE; 
                    if(current_word >= word_count) begin
                        state <= DONE; 
                    end
                    else state <= WRITE; 
                end

                WRITE: begin
                        // master_writedata <= read_data; 
                        // current_word <= current_word + 1; // Might be updating multiple times
                        if (current_word >= word_count) begin
                            state <= DONE;
                        end else begin
                            if(!master_waitrequest) begin
                                state <= SET_ADDR;
                                current_word <= current_word + 1;
                            end 
                        end
                end


                DONE: begin
                    // Copying process complete
                    state <= FIRST_3;
                    slave_waitrequest <= 0; 

                    flag1 <= 0; 
                    flag2 <= 0; 
                    flag3 <= 0; 

                    current_word <= 0;
                    base_dest_address <= 0;
                    base_src_address <= 0;
                    word_count <= 0;
                end
            endcase
        end
    end

endmodule