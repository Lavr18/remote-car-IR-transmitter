`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.01.2018 09:48:50
// Design Name: 
// Module Name: Counter_TB
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


module Counter_TB(

    );
    
    //inputs
    reg CLK;
    reg RESET;
    reg [3:0] COMMAND;
    //outputs
    wire IR_LED;
    
    
    //instantiate the test for a module IR_Transmitter_SM    
    IR_Transmitter_SM uut (
    .RESET(RESET),
    .CLK(CLK),
    .COMMAND(COMMAND),
    .IR_LED(IR_LED)
    );
    
    //activities for our testbench
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end 
    
    initial begin
        COMMAND=4'b1001;
        RESET=0;
        #499000
        RESET=1;
        #100
        RESET=0;
        #1500000
        RESET=1;
        #100
        RESET=0;
        #15000000
        COMMAND=4'b0001;  
    end           
  
    
    
endmodule
