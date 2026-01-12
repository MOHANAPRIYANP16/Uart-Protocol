# Uart-Protocol

## Introduction

This project focuses on the implementation of the Universal Asynchronous Receiver/Transmitter (UART) protocol on an FPGA, enabling reliable FPGA-to-FPGA serial communication. The design includes a complete UART transmitter, receiver, and baud rate generator developed using synthesizable Verilog RTL. A key feature of the project is the support for **multiple configurable baud rates**, allowing the communication speed to be selected dynamically based on system requirements.

By implementing selectable baud rate control along with standard UART framing, the design demonstrates flexible and robust asynchronous communication without a shared clock. 

![alt text](https://github.com/MOHANAPRIYANP16/Uart-Protocol/blob/main/Images/fpga.png)

### Key Features

- Supports configurable baud rates: 9600 / 19200 / 57600 / 115200 bps  
- Start and stop bit detection  
- Standard UART data format: 8-bit, no parity, 1 stop bit (8-N-1)  
- 16× oversampling for accurate data reception  
- Internal loopback mode for self-testing  
- Testbench-based verification for all modules  
- Reset-clean and fully synthesizable RTL design  


## Module Descriptions 

- **Baud Rate Generator**
  - Generates UART timing from the system clock  
  - Supports multiple selectable baud rates  
  - Provides baud tick for transmission  
  - Provides 16× baud tick for receiver oversampling  

- **UART Transmitter (TX)**
  - Converts parallel data to serial format  
  - Generates start and stop bits  
  - Transmits data LSB first  
  - Indicates transmission busy status  

- **UART Receiver (RX)**
  - Detects start bit and synchronizes reception  
  - Uses 16× oversampling for accurate sampling  
  - Reconstructs received data using a shift register  
  - Validates stop bit and signals receive completion  

- **Top-Level Module**
  - Integrates baud generator, TX, and RX modules  
  - Manages internal signal connections  
  - Supports optional loopback mode  
  - Provides clean external interfaces  

- **Testbench (Verification)**
  - Generates clock and reset signals  
  - Applies stimulus to the transmitter  
  - Enables loopback for self-testing  
  - Verifies functionality through waveform analysis  

---

## Hardware Implementation

Target Platform: FPGA (Generic / Vendor-independent)  
System Clock: 100 MHz  
UART Interface: FPGA-to-FPGA / External UART device  
Baud Rate Support: 9600 / 19200 / 57600 / 115200 bps  
Input Controls: Pushbutton (transmit trigger), parallel data input  
Output Interface: UART serial TX/RX lines  
Synthesis Tool: Icarus Verilog / FPGA vendor tools  

## System Behavior

Pressing the pushbutton initiates UART transmission of the input data  
The transmitter sends data using standard UART framing (8-N-1)  
The receiver detects the start bit and samples incoming data using 16× oversampling  
Received data is reconstructed and made available at the output  
Internal loopback mode enables self-testing without external hardware 

## UART Timing Summary

| Baud Rate (bps) | Bit Time (µs) | RX Oversample Tick (µs) | UART Frame Time (8-N-1, µs) |
|-----------------|---------------|--------------------------|-----------------------------|
| 9600            | 104.16        | 6.51                     | 1041.6                      |
| 19200           | 52.08         | 3.26                     | 520.8                       |
| 57600           | 17.36         | 1.085                    | 173.6                       |
| 115200          | 8.68          | 0.542                    | 86.8                        |

### Notes
- **Bit Time** = 1 / Baud Rate  
- **RX Oversample Tick** = Bit Time / 16  
- **UART Frame Time** = 10 × Bit Time (1 start + 8 data + 1 stop)

---

## Baud Rate Control Encoding

The baud rate controller uses a 2-bit encoded control signal to select one of multiple predefined clock divider values. This selection logic configures the baud generator, which produces timing pulses for UART TX and RX operation.

2'b00 → 9600 bps  
2'b01 → 19200 bps  
2'b10 → 57600 bps  
2'b11 → 115200 bps  

---
### State Diagram :

![alt text](https://github.com/MOHANAPRIYANP16/Uart-Protocol/blob/main/Images/state_diagram.png)


## Verilog Files

<details>
<summary><strong>Design Files</strong></summary>
 <details>
<summary><strong>Transmitter.v</strong></summary>

```verilog
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
```
</details> 

<details>
<summary><strong>Reciever.v</strong></summary>

```verilog
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
```
</details>

<details>
<summary><strong>Baud Rate Generator.v</strong></summary>

```verilog 
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
```

</details> 



<details>
<summary><strong>Top Module.v</strong></summary>

```verilog 
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

```

</details> 


</details> 


<details>
<summary><strong>Test Bench.v</strong></summary>

```verilog 

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
```
</details> 


### 5. Functional Simulation
Run behavioral simulation to verify UART transmission and reception using the testbench.

![alt text](https://github.com/MOHANAPRIYANP16/Uart-Protocol/blob/main/Images/simulation%20waveform.png)


#### Schematic:

![alt text](https://github.com/MOHANAPRIYANP16/Uart-Protocol/blob/main/Images/RTl%20analysis%20shematic.png)


---

### 6. Synthesis
Synthesize the RTL design to generate a gate-level netlist and check for timing or logic issues.

![alt text](https://github.com/MOHANAPRIYANP16/Uart-Protocol/blob/main/Images/synthesis.png)

### 7. Resource Utilization 

![alt text](https://github.com/MOHANAPRIYANP16/Uart-Protocol/blob/main/Images/utilization.png)

### 8. Timing Report

![alt text](https://github.com/MOHANAPRIYANP16/Uart-Protocol/blob/main/Images/timing%20summary%20.png)

### 9. Power Report 

![alt text](https://github.com/MOHANAPRIYANP16/Uart-Protocol/blob/main/Images/Power%20Report.png)

### 10. implwmwntation :

![alt text](image.png)



