module rx (
    input clk,
    input clk_out2,
    input rx,
    input rst,
    output reg rx_done,
    output reg [7:0] data_out
);

  reg [2:0]bit_pos ;
  reg [3:0] samp_cnt ;
  reg [1:0] state;
  reg [7:0] shift;


parameter rx_idle = 2'b00;
parameter rx_start = 2'b01;
parameter rx_data = 2'b10;
parameter rx_stop = 2'b11;  

always @(posedge clk or posedge rst)
begin

if (rst)
begin
     rx_done <=0;
     data_out <= 0;
     bit_pos <=0;
     samp_cnt <= 0;
     state <= rx_idle;
     shift <=0;
end

else 

begin
    rx_done <=1'b0;

    if (clk_out2)
    begin
       case(state)
           
           rx_idle :begin
                if(!rx)
                begin
                    state <= rx_start;
                    samp_cnt <= 1'b0;

                end
                
           end

           rx_start :begin
                if (samp_cnt == 4'd7)
                begin
                    if (!rx)
                begin
                     samp_cnt<=4'b0;
                     state <= rx_data;
                     bit_pos <= 3'b0;
                end
                else begin
                    state <= rx_idle;
                    samp_cnt <= 4'b0;
                end
                end
                else 
                begin
                    samp_cnt <= samp_cnt +1'b1;
                end

           end

           rx_data :begin
             if (samp_cnt == 4'd15) 
             begin
                   samp_cnt <=4'b0;
                   shift[bit_pos] <= rx;

                if (bit_pos == 3'd7)
                   begin
                      state <= rx_stop ;
                      bit_pos <= 3'b0;
                   end
                else 
                   begin
                       bit_pos <= bit_pos + 1'b1;
                   end
             end 
             else 
             begin
                samp_cnt <= samp_cnt +1'b1;
             end

           end

           rx_stop : begin

            
            if (samp_cnt == 4'd15)
            begin
                if (rx)
            begin
                data_out <= shift ;
                rx_done <= 1'b1;
            end
               state <= rx_idle; 
                samp_cnt <= 4'b0;
            end
            else 
             begin
                samp_cnt <= samp_cnt +1'b1;
             end
             
             
           end
           default : begin
            state <= rx_idle;
           end
       endcase
    
     
    end



end

end
endmodule