`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2016 14:09:05
// Design Name: 
// Module Name: Generic_counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Generic_counter(
    CLK,
    RESET,
    ENABLE,
    TRIGER_OUT_1,
    TRIGER_OUT_2,
    COUNT
    );
    
    parameter COUNTER_WIDTH = 4;
    parameter COUNTER_MAX = 9;
    
    input CLK;
    input RESET;
    input ENABLE;
    output TRIGER_OUT_1;
    output TRIGER_OUT_2;
    output [COUNTER_WIDTH-1:0] COUNT;
    
    initial
    count_value = 0;
    //Declare registers that hold the current count value and trigger out between clock cycles
    
    reg [COUNTER_WIDTH-1:0] count_value = 0;
    reg Trigger_out_1 = 0;
    reg Trigger_out_2;
    
    //Synchronous logic for value of count_value
    always@(posedge CLK) begin
       if(RESET)
          count_value <= 0;
       else begin
          if(ENABLE) begin
             if(count_value == COUNTER_MAX)
                count_value <= 0;
             else
                count_value <= count_value + 1;
          end
       end
    end
    
    //Synchronous logic for value of Trigger_out
    //Consists of two Trigger_out as one wi110ll give a wide pulses for IR_LED output
    //and the other one will be used for counting up
    always@(posedge CLK) begin
       if(RESET) begin
          Trigger_out_1 <= 0;
          Trigger_out_2 <= 0;
       end
       else begin
          if(ENABLE && (count_value == COUNTER_MAX)) begin
             Trigger_out_1 <= 1;
             Trigger_out_2 <= 1;
          end 
          // set Trigger_out_1 to 0, once the counter reached the half counting period
          else if (ENABLE && (count_value == (COUNTER_MAX/2) + 1))
             Trigger_out_1 <= 0;
          else
             Trigger_out_2 <= 0;
       end
    end
    
    //Assignment that tie the count_value and Trigger_out to COUNT and TRIG_OUT respectively
    assign COUNT = count_value;
    assign TRIGER_OUT_1 = Trigger_out_1;
    assign TRIGER_OUT_2 = Trigger_out_2;   
    
    
    
endmodule
