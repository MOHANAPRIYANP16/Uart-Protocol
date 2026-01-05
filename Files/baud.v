`timescale 1ns/1ps
module baud #(parameter N = 100_000_000) (
    input clk ,
    input rst ,
    input [1:0] baud_fix,
    output reg clk_out1,
    output reg clk_out2 
);
 parameter  baud_rate_tx_9600 =N /9600;
 parameter baud_rate_rx_9600  =N/(9600*16);
 parameter  baud_rate_tx_19200 =N /19200;
 parameter baud_rate_rx_19200  =N/(19200*16);
 parameter  baud_rate_tx_57600 =N /57600;
 parameter baud_rate_rx_57600  =N/(57600*16);
 parameter  baud_rate_tx_115200 =N /115200;
 parameter baud_rate_rx_115200  =N/(115200*16);
 

 reg [31:0] baud_rate_tx;
 reg [31:0]baud_rate_rx;

always @(posedge clk )
begin

  case (baud_fix)
  
  2'b00 :begin
       baud_rate_tx =  baud_rate_tx_9600;
       baud_rate_rx =  baud_rate_rx_9600;
  end

  2'b01 : begin
    baud_rate_tx =  baud_rate_tx_19200;
    baud_rate_rx =  baud_rate_rx_19200;
  end
  2'b10 : begin
    baud_rate_tx =  baud_rate_tx_57600;
    baud_rate_rx =  baud_rate_rx_57600;
  end
  2'b11 : begin
    baud_rate_tx =  baud_rate_tx_115200;
    baud_rate_rx =  baud_rate_rx_115200;
  end

  endcase


end

 


  reg [31:0] counter1 = 0 ;
  reg [31:0] counter2 = 0 ;


  always @(posedge clk or posedge rst )
  begin
    if (rst)
    begin
      counter1 <= 0;
     
      clk_out1 <= 1'b0;
     

    end
     
    else if(counter1 == (baud_rate_tx-1))
    begin
      counter1 <= 0;


       clk_out1 <= 1'b1;

    end

    else 
    begin
     counter1 <= counter1+1'b1;
     clk_out1 <= 1'b0;

    end
  end

always @(posedge clk or posedge rst)
  begin
     if (rst)
    begin
      counter2 <= 0;
     
      clk_out2 <= 1'b0;
     end
   else if(counter2 == (baud_rate_rx -1))
    begin
      counter2 <= 0;
       clk_out2 <= 1'b1;

    end

    else 
    begin
     counter2 <= counter2+1'b1;
     clk_out2 <= 1'b0;
    end
  end


    
endmodule