module tx (
    input clk,
    input rst,
    input clk_out1,
    input [7:0] data_in,
    input sbtn,
    output reg tx,
    output reg tx_busy
);

parameter idle = 2'b00;
parameter start = 2'b01;
parameter data = 2'b10;
parameter stop = 2'b11; 


reg [7:0] shift_reg ;
reg [2:0] bitpos ;
reg [1:0] state;


always @(posedge clk or posedge rst )
begin
  if (rst)
  begin
      tx <=1'b1;
      state <= idle;
      tx_busy <= 1'b0;
      shift_reg <= 8'b0;
      bitpos <= 3'b0;

  end

  else 
  begin
    case (state)
      
      idle : begin

        tx <= 1'b1;
        tx_busy <= 1'b0;
        if(sbtn)
        begin
            state <= start ;
            shift_reg <= data_in;
            tx_busy <= 1'b1;
        end
        else 
        state <= idle ;
      end
      start : begin
        if ((clk_out1)&&(!sbtn))
        begin
            tx <= 1'b0;
            state <= data ;
            bitpos <= 3'b0;
        end
        else 
        begin
        tx <= 1'b1;
        state <= start;
        end
      end
      data : begin
        if (clk_out1)
        begin

            tx <= shift_reg [bitpos];

            if(bitpos == 3'd7)
            begin
                state <= stop;
               
            end
            else 
            begin
                
                bitpos <=bitpos + 1'b1;
            end
        end
      end
      stop :begin
        if(clk_out1)
        begin
            state <= idle ;
            tx <= 1'b1;
            tx_busy <= 1'b0;
        end
      end

      default :begin
        tx <= 1'b1;
        state <= idle ;
        tx_busy <= 1'b0;
      end

    endcase
   
  end
end

endmodule