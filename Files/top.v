module top (
    input clk,
    input rst,
    input [1:0]baud_fix,
    input [7:0] data_in,
    input sbtn,
    input rx_pin,
    input loopback_en,     
    output tx,
    output [7:0] data_out
  
);

wire  clk_out1;
wire  clk_out2;
wire  rx_done;
wire  tx_busy;
wire  rx_int;

assign rx_int = loopback_en ? tx : rx_pin;


tx inst1 ( .clk(clk),
    .rst(rst),
    .clk_out1(clk_out1),
    .data_in(data_in),
    .sbtn(sbtn),
    .tx(tx),
    .tx_busy(tx_busy));

rx inst2 ( .clk(clk),
    .rst(rst),
    .clk_out2(clk_out2),
    .rx(rx_int),
    .rx_done(rx_done),
    .data_out(data_out))  ;

 baud inst3 (.clk(clk) ,
    .rst(rst) ,
    .baud_fix(baud_fix),
    .clk_out1(clk_out1),
    .clk_out2(clk_out2) )  ;   

endmodule

