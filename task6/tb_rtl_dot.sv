module tb_rtl_dot();
    logic clk = 0;
    logic rst_n;
    logic slave_waitrequest;
    logic [3:0] slave_address;
    logic slave_read; logic [31:0] slave_readdata;
    logic slave_write; logic [31:0] slave_writedata;

    logic master_waitrequest;
    logic [31:0] master_address;
    logic master_read; logic [31:0] master_readdata; logic master_readdatavalid;
    logic master_write; logic [31:0] master_writedata;

    dot dut(.*);

    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        #10;

        rst_n = 1;
        #10;

        slave_address = 4'b0010;
        slave_write = 1;
        slave_writedata = 1;
        #10;

        slave_write = 0;
        #10;

        slave_address = 4'b0011;
        slave_write = 1;
        slave_writedata = 2;
        #10;

        slave_address = 4'b0101;
        slave_write = 1;
        slave_writedata = 3;
        #10;

        slave_address = 4'b0000;
        #10;

        slave_write = 0;
        #10;

        master_readdatavalid = 1;
        master_waitrequest = 0;
        master_readdata = 1;
        #10;

        master_readdatavalid = 0;
        master_waitrequest = 1;
        #10;

        master_readdatavalid = 1;
        master_waitrequest = 0;
        master_readdata = 2;
        #10;

        master_readdatavalid = 0;
        #10;

        master_readdatavalid = 1;
        master_waitrequest = 0;
        master_readdata = 3;
        #10;

        master_readdatavalid = 0;
        master_waitrequest = 1;
        #10;

        master_readdatavalid = 1;
        master_waitrequest = 0;
        master_readdata = 4;
        #10;

        master_readdatavalid = 0;
        master_waitrequest = 1;
        #10;

        master_readdatavalid = 1;
        master_waitrequest = 0;
        master_readdata = 2;
        #10;

        master_readdatavalid = 0;
        master_waitrequest = 1;
        #10;

        slave_read = 1;
        slave_address = 0;

        #10;
        $display(dut.slave_readdata);
        $stop;
    end 

    
endmodule: tb_rtl_dot
