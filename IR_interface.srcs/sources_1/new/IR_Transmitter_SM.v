`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: the University of Edinburgh
// Engineer: Mr Aliaksei Laurynovich
// 
// Create Date: 23.02.2018 09:29:01
// Design Name: IR Transmitter SM
// Module Name: IR_Transmitter_SM
// Project Name: Digital Systems Laboratory 4
// Target Devices: xilinx Artix 7 FPGA 
// Tool Versions: 
// Description: This module produces the pulse sequencies to control the cars remotely. 
//              There are 3 inputs: RESET - to reset the operation
//                                  CLK - connected to the internal clock
//                                  [3:0] COMMAND - 4 bit command to choose the car direction
//              And 1 output:       IR_LED - at 10Hz produces the series of pulses of reqired width to control the car.
//              The user should uncomment the parameters for the car type he is using
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IR_Transmitter_SM(
    input RESET,
    input CLK,
    input [3:0] COMMAND,
    output IR_LED
    );
    
     // Registers to define the state of the SM
    reg [2:0] Curr_state;
    reg [2:0] Next_state;
    
    // Register to count the pulse amount
    reg [9:0] Curr_count; 
    
    // Registers to control the generic counter operation
    reg PulseEnable; 
    reg PulseReset; 
    
    // Wires to connect TRIGGER_OUT of generic counter instances
    wire Bit24triggOut;
    wire Bit12triggOut_1; 
    wire Bit12triggOut_2; 

    ////////////////////////////////////////////////////////////////////////////////
    ///////////// UNCOMMENT THE PARAMETERS FOR THE CAR BEING USED!!! ///////////////
    ////////////////////////////////////////////////////////////////////////////////
    
//    // BLUE-CODED CAR PARAMETERS
//    parameter StartBurstSize = 191;
//    parameter CarSelectBurstSize = 47;
//    parameter GapSize = 25;
//    parameter AssertBurstSize = 47;
//    parameter DeAssertBurstSize = 22; 
//    parameter CounterMax = 2777; //defines the counter frequency. 2777 for 36kHz
    
//    // RED-CODED CAR PARAMETERS
//    parameter StartBurstSize = 192;
//    parameter CarSelectBurstSize = 24;
//    parameter GapSize = 24;
//    parameter AssertBurstSize = 48;
//    parameter DeAssertBurstSize = 24; 
//    parameter CounterMax = 2777; //defines the counter frequency. 2777 for 36kHz

//    // YELLOW-CODED CAR PARAMETERS
//    parameter StartBurstSize = 88;
//    parameter CarSelectBurstSize = 22;
//    parameter GapSize = 40;
//    parameter AssertBurstSize = 44;
//    parameter DeAssertBurstSize = 22; 
//    parameter CounterMax = 2500; //defines the counter frequency. 2500 for 40kHz
    
    // GREEN-CODED CAR PARAMETERS
    parameter StartBurstSize = 88;
    parameter CarSelectBurstSize = 44;
    parameter GapSize = 40;
    parameter AssertBurstSize = 44;
    parameter DeAssertBurstSize = 22; 
    parameter CounterMax = 2666; //defines the counter frequency. 2666 for 37.5kHz               

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

                    
    // State names
    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter CAR_SELECT = 3'b010;
    parameter RIGHT = 3'b011;
    parameter LEFT = 3'b100;
    parameter BACKWARD = 3'b101;
    parameter FORWARD = 3'b110;

                
    
    
    //The 24 bit counter to convert 100MHz Clock frequency to 10Hz
    Generic_counter # (.COUNTER_WIDTH(24),
                       .COUNTER_MAX(9999999)
                       )
    Bit24Counter (
    .CLK(CLK),
    .RESET(1'b0),
    .ENABLE(1'b1),
    .TRIGER_OUT_2(Bit24triggOut) //connected to TRIGER_OUT_2, which represents a normal generic counter trigger for counting up
    );    

    // #1 12-BIT COUNTER: with controllable ENABLE and RESET - used for IR_LED output
    Generic_counter # (.COUNTER_WIDTH(12),
                       .COUNTER_MAX(CounterMax)
                       )
    Bit12Counter_1 (
    .CLK(CLK),
    .RESET(PulseReset),  //PulseReset
    .ENABLE(PulseEnable), //PulseEnable
    .TRIGER_OUT_1(Bit12triggOut_1) //connected to TRIGER_OUT_1, which represents a 50/50 counting period trigger
    );    
    
    // #2 12-BIT COUNTER: provides the required frequency for a counter
    Generic_counter # (.COUNTER_WIDTH(12),
                       .COUNTER_MAX(CounterMax)
                       )
    Bit12Counter_2 (
    .CLK(CLK),
    .RESET(1'b0),
    .ENABLE(1'b1),
    .TRIGER_OUT_2(Bit12triggOut_2) //connected to TRIGER_OUT_2, which represents a normal generic counter trigger for counting up
    );
    
   
                       
    //Counter setup
    initial begin
        Curr_count = 0;
    end    
    // Increment the counter when not in IDLE state
    always@(posedge CLK) begin
        if (Curr_state == IDLE)
            Curr_count <= 0;
        else
            if (Bit12triggOut_2) // Increment on #2 12-BIT COUNTER trigger
                Curr_count <= Curr_count + 1;  
    end
    
    
    // STATE MACHINE   
    // Sequential
    always@(posedge CLK) begin                          
       // This is a synchronous RESET
        if(RESET) begin
          Curr_state <= IDLE;
          // Reset #1 12-BIT COUNTER 
          PulseReset <= 1;
        end   
        else begin
          PulseReset <= 0;
          Curr_state <= Next_state;
        end
    end

    always@(Curr_state or COMMAND or Curr_count or Bit24triggOut) begin
           
        case(Curr_state)
        
           IDLE  : begin           
              // Enable the SM only when 10Hz triggered
              if (Bit24triggOut) begin
                 Next_state <= START;
              end
              // Else, hold this state and keep #1 12-BIT COUNTER disabled
              else begin
                 Next_state <= Curr_state;
                 PulseEnable <= 0; 
              end
           end
        
           START  : begin
              // Control #1 12-BIT COUNTER to give output pulses
              if (Curr_count <= StartBurstSize)
                  PulseEnable <= 1; //activate #1 12-BIT COUNTER to give pulses to the output
              else
                  PulseEnable <= 0; //deactivate #1 12-BIT COUNTER 
              // if the counter value is less than start and gap sequence, then stay in this state and enable counter
              if (Curr_count == StartBurstSize + GapSize + 1)
                  Next_state <= CAR_SELECT;             
              else 
                  Next_state <= Curr_state;
           end
           
           CAR_SELECT  : begin
              // control #1 12-BIT COUNTER  to give output pulses
              if (Curr_count <= StartBurstSize + GapSize + CarSelectBurstSize)
                  PulseEnable <= 1; //activate #1 12-BIT COUNTER  to give pulses to the output
              else
                  PulseEnable <= 0; //deactivate #1 12-BIT COUNTER 
              // if the counter value is equal to start-gap-select-gap + 1 sequence, then go to the next state
              if (Curr_count == StartBurstSize + GapSize + CarSelectBurstSize + GapSize + 1)
                  Next_state <= RIGHT;
              else 
                  Next_state <= Curr_state;
           end
           
           RIGHT  : begin             
              // control #1 12-BIT COUNTER to give output pulses
              if (Curr_count <= StartBurstSize + GapSize + CarSelectBurstSize + GapSize
                  + AssertBurstSize -(~|COMMAND[3]*DeAssertBurstSize))
                  PulseEnable <= 1; //#1 12-BIT COUNTER  to give pulses to the output
              else
                  PulseEnable <= 0; //deactivate #1 12-BIT COUNTER 
              if (Curr_count == StartBurstSize + GapSize + CarSelectBurstSize + GapSize
               + AssertBurstSize -(~|COMMAND[3]*DeAssertBurstSize) + GapSize + 1)
                  Next_state <= LEFT;
              else 
                  Next_state <= Curr_state;
           end
           
           LEFT  : begin 
              // control #1 12-BIT COUNTER give output pulses
              if (Curr_count <= StartBurstSize + GapSize + CarSelectBurstSize + GapSize
                  + AssertBurstSize -(~|COMMAND[3]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[2]*DeAssertBurstSize))
                  PulseEnable <= 1; //activate #1 12-BIT COUNTER  to give pulses to the output
              else
                  PulseEnable <= 0; //deactivate #1 12-BIT COUNTER 
              if (Curr_count == StartBurstSize + GapSize + CarSelectBurstSize + GapSize
                  + AssertBurstSize -(~|COMMAND[3]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[2]*DeAssertBurstSize) + GapSize + 1)
                  Next_state <= BACKWARD;
              else 
                  Next_state <= Curr_state;
           end
           
           BACKWARD  : begin
              // control #1 12-BIT COUNTER to give output pulses
              if (Curr_count <= StartBurstSize + GapSize + CarSelectBurstSize + GapSize
                  + AssertBurstSize -(~|COMMAND[3]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[2]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[1]*DeAssertBurstSize))
                  PulseEnable <= 1; //activate #1 12-BIT COUNTER  to give pulses to the output
              else
                  PulseEnable <= 0; //deactivate #1 12-BIT COUNTER 
              if (Curr_count == StartBurstSize + GapSize + CarSelectBurstSize + GapSize
                  + AssertBurstSize -(~|COMMAND[3]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[2]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[1]*DeAssertBurstSize) + GapSize + 1)
                  Next_state <= FORWARD;
              else 
                  Next_state <= Curr_state;
           end                                     
               
           FORWARD  : begin
              // control #1 12-BIT COUNTER to give output pulses
              if (Curr_count <= StartBurstSize + GapSize + CarSelectBurstSize + GapSize
                  + AssertBurstSize -(~|COMMAND[3]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[2]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[1]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[0]*DeAssertBurstSize))
                  PulseEnable <= 1; //activate #1 12-BIT COUNTER  to give pulses to the output
              else
                  PulseEnable <= 0; //deactivate #1 12-BIT COUNTER 
              if (Curr_count == StartBurstSize + GapSize + CarSelectBurstSize + GapSize
                  + AssertBurstSize -(~|COMMAND[3]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[2]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[1]*DeAssertBurstSize) + GapSize
                  + AssertBurstSize -(~|COMMAND[0]*DeAssertBurstSize) + GapSize + 1)
                  Next_state <= IDLE;
              else 
                  Next_state <= Curr_state;
           end
                                                               
           default :
               Next_state <= IDLE;
        endcase
    end


    assign IR_LED = Bit12triggOut_1;  // Make the output to follow the TRIGGER_OUT of controllable 12 bit counter    
               
endmodule
