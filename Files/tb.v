`timescale 1ns/1ps

module tb #(parameter N = 100_000_000) ;

    reg  clk;
    reg  rst;
    reg  [1:0]baud_fix;
    reg  [7:0] data_in;
    reg  sbtn;
    reg  rx_pin;
    reg  loopback_en;     
    wire tx;
    wire [7:0] data_out;
   

    

    top uut (
        .clk(clk),
        .rst(rst),
        .baud_fix(baud_fix),
        .data_in(data_in),
        .sbtn(sbtn),
        .rx_pin(rx_pin),
        .loopback_en(loopback_en),     
        .tx(tx),
        .data_out(data_out)
       
    );

    initial
     begin
         clk = 0 ;
         forever #5 clk = ~clk ;
         
     end

     initial 
     begin

        $dumpfile ("uart.vcd");
        $dumpvars(0,tb);
        baud_fix = 2'b11;
        rst = 1;
        sbtn =0;
        data_in = 8'h00;
        rx_pin = 1'b1;
        loopback_en = 1'b1; #50;
        
        rst =0;
        #100;
        data_in = 8'hA5;
        sbtn = 1;
        #10;
        sbtn =0;
        #2_000_000;
        $finish;
     end
   

    
endmodule