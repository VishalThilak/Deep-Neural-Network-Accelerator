module vga_avalon(input logic clk, input logic reset_n,
                  input logic [3:0] address,
                  input logic read, output logic [31:0] readdata,
                  input logic write, input logic [31:0] writedata,
                  output logic [7:0] vga_red, output logic [7:0] vga_grn, output logic [7:0] vga_blu,
                  output logic vga_hsync, output logic vga_vsync, output logic vga_clk);

    
    // your Avalon slave implementation goes here
    logic [7:0] brightness;
    logic VGA_BLANK, VGA_SYNC;
    logic [7:0] x_pos;
    logic [6:0] y_pos;
    logic plot;

    localparam integer MAX_X = 9'd159;
    localparam integer MAX_Y = 8'd119;

    assign plot = (address == 0) && (x_pos < MAX_X && x_pos >= 0) && (y_pos < MAX_Y && y_pos >= 0) && write;
    assign readdata = 0;

    vga_adapter #( .RESOLUTION("160x120"), .MONOCHROME("TRUE"), .BITS_PER_COLOUR_CHANNEL(8) )
	vga(.resetn(reset_n), .clock(clk), .colour(brightness), .x(x_pos), .y(y_pos), .plot(plot), .VGA_R(vga_red), .VGA_G(vga_grn), .VGA_B(vga_blue), .VGA_HS(vga_hsync), .VGA_VS(vga_vsync), .VGA_BLANK(VGA_BLANK), .VGA_SYNC(VGA_SYNC), .VGA_CLK(vga_clk));

    always_ff @(posedge clk) begin
        if(~reset_n)begin
            x_pos <= 0;
            y_pos <= 0;
            brightness <= 0;
        end else begin
            y_pos <= writedata[30:24];
            x_pos <= writedata[23:16];
            brightness <= writedata[7:0];
        end

    end
    // NOTE: We will ignore the VGA_SYNC and VGA_BLANK signals.
    //       Either don't connect them or connect them to dangling wires.
    //       In addition, the VGA_{R,G,B} should be the upper 8 bits of the VGA module outputs.

endmodule: vga_avalon



/*

    logic [7:0] vga_x; 
    logic [6:0] vga_y; 
    logic [6:0] brightness; // NOT SURE WHAT TO DO WITH THIS
    logic vga_plot; 
    logic [7:0] vga_colour; 

    logic [6:0] x_plot; 
    logic [7:0] y_plot; 

    assign readdata = 32'd0; // SPEC SAYS WRITE ONLY, SO SHOULD BE THIS, NOT SURE THOUGH
                             // COULD SIMPLY ASSIGN vga_x, vga_y, brightness of writedata to readdata
     
    assign vga_plot = x_plot & y_plot; // Write ignored if out of bounds

    assign vga_colour = brightness; // BRIGHTNESS controls vga_colour I think since they said lab has been 
                                    // modified to output 8b grayscale instead of 3b colour

    always_ff @( posedge clk ) begin
        if(!reset_n) begin
            x_plot <= 0; 
            y_plot <= 0; 
            vga_x <= 8'd0; 
            vga_y <= 7'd0; 
            brightness <= 8'd0; 
        end

        else begin
            if((address == 4'd0) && write) begin // NOT SURE ABOUT write (shud be right imo)
                vga_x <= writedata[23:16];
                vga_y <= writedata[30:24]; 
                brightness <= writedata[7:0]; 

                x_plot <= ((vga_x >= 7'd0) && (vga_x <= 7'd159)) ? 1: 0;
                y_plot <= ((vga_y >= 7'd0) && (vga_y <= 7'd119)) ? 1: 0;
            end

            else begin
                // IGNORE
            end
        end
    end
    */