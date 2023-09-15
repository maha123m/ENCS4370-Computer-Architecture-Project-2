// Define global variables
reg [2:0]current_state;
reg [2:0]next_state;
reg [31:0]IR;	


module AllTheSystem ( 
	
	input clk,
	input reset,
	
	// Observing the values of the generated signals
	output reg PCSrc1, 
	output reg PCSrc0,	   
	output reg RegWrite, 
	output reg ALUSrc1, 
	output reg ALUSrc0, 
	output reg [2:0] ALUOp,
	output reg  R_mem, 
	output reg W_mem,
	output reg WB,
	output reg push,
	output reg pop,
	
	
	///Instruction Decode Part 
	output reg [31:0] Rs1, // (Bus A )Output data from register 1
    output reg [31:0] Rs2, // (Bus B) Output data from register 2
    output reg [31:0] Rd, // (Bus W) Output data from register 3
	
	
	///ALU Part
	output reg [31:0] outputOfALU, // Just to verify that the ALU works properly 
	
	///immediate14 Part
	output reg [31:0]extended_immediate14, 
	///immediate24 Part
	output reg [31:0]extended_immediate24,
	
	
	///just for depugging the code for store
	output reg [31:0]outputOfTheStore, 
	
	///Shift amount constant
	output reg [4:0]shiftAmount
	
);	   

	/// Instruction Fetch
	reg [31:0] memory [0:31];
	reg [31:0] PC; 	 
	
	///Instruction Decode
	reg [31:0] writeData; 
	reg [31:0]D0; 
	reg [31:0]D1;
    reg [31:0]D2; 
	reg [31:0]D3;  
    reg [31:0]Y;
	reg [4:0] Registers[0:31];
	
	
	reg [4:0] AddressOfRd;	 // Address for Rd
	reg [4:0]AddressOfRs1;  // Address for RS1
	reg [4:0]AddressOfRs2;  // Address for RS2	
		
		
	///Control Unit Signals Generated
	reg [1:0]Type;
	reg [4:0]Function; 
	
	///ALU Part
 	 reg [31:0] operandA;    // Operand A
     reg [31:0] operandB;    // Operand B      
     reg zero;               // Zero flag indicating if the result is zero
		 

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	///Data Memory 	   
	reg [31:0] address,data_in;
    reg [31:0] data_out;
	
	///Data Memory
	reg [31:0] data_memory [31:0];	
	
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
	///Write back stage
    reg [31:0]outOfDownMux;
	
	//Extenders 14 and 24
	reg [13:0] immediate14;  
	reg [23:0] immediate24;	
	
	//Up adder
	reg [31:0] outputOfUpAdder;	
	
	///Stack Part
	reg [31:0] outputOfStack;
	reg empty,full;				
	parameter STACK_DEPTH = 8;   // This is the maximum # of inner functions for this stack
    reg [31:0] stack [STACK_DEPTH-1:0];
    reg [2:0] top;	 //Stack Pointer	
	
	//Branch Target Address
	reg [31:0] outputOfBTA;
	
	///outputOfMuxAfterBTA
	reg [31:0]outputOfMuxAfterBTA;	  
	
	///outputOfMuxAfterStack
	reg [31:0]outputOfMuxAfterStack;

	initial begin 
		
		
	memory[0] = 32'h10040034; //LW Rd = 9 
	memory[1] = 32'h08840000; //ADD Rd = Rd + 8	(Rd = 17)  
	memory[2] = 32'h10841000;  // SUB Rd = Rd - 7 (Rd = 10)	 
	memory[3] = 32'h18040004;  //SW Rd
	memory[4] = 32'h00000022; //J to the PC = 8	 
										
	
	memory[5] = 32'h10040034; //LW  
	memory[6] = 32'h08840000; //ADD
	memory[7] = 32'h08840000; //ADD	
	
	memory[8] =	32'h08000062;   //Jal to PC = 20 
	memory[9] = 32'h18028006;	//Rd = SLRV with Shift amount 
	
	memory[10] = 32'h10040034; //LW Rd = 9 
	memory[11] = 32'h08840000; //ADD Rd = Rd + 8	(Rd = 17)  
	memory[12] = 32'h10841000;  // SUB Rd = Rd - 7 (Rd = 10)	
	
	memory[20] = 32'h00840287;	//Rd = SLL with Shift amount  = 5 
	
	end	
	
	initial top = 3'b000;
	
	
	integer i;
	always @(posedge clk)  
		case (current_state) 	
		 	0: 
				next_state = 1;
			1: 
				next_state = 2;
			2: 
				next_state = 3;
			3: 
				next_state = 4;
			4: 
				next_state = 0;
 		endcase	   	
		 
		 
	always @(posedge clk) 
 		current_state = next_state;
	
	
	always @(posedge clk, posedge reset)
		
		if (reset)	begin  
			
			current_state = 4;
			PC = 32'h00000000;
			Rs1 = 32'd0;
			Rs2 = 32'd0;
			Rd = 32'd0;
			Y = 32'h00000000;	
			
			
			for (i = 0; i < 31; i = i + 1)
     			 Registers[i] <= 32'h00000000;
		end	   

	else if (current_state == 0) begin	 
		
		//instruction fetch
		IR = memory[PC]; 
		
		//$display ("%x", IR);	 
		
		//grep the type and the function to determine the kind of the inctruction
		Type = IR[2:1]; 
        Function = IR[31:27];  	
		
		
		//$display ("%b", Type);
		
		///Grep the constant for the Shift process
		shiftAmount = IR [11:7];
		
		//pop signal
		pop = IR[0];  
		
		
		/// R-type
		if (Type == 2'b00)		
			if (Function == 5'b00000 || Function == 5'b00001 || Function == 5'b00010) begin	 ///ADD	|| AND || SUB

				PCSrc1 = 1'b1;
				PCSrc0 = 1'b0;
			    RegWrite = 1'b1;
		        ALUSrc1 = 1'b0; 
				ALUSrc0 = 1'b0; 
				
				if (Function == 5'b00000)
					ALUOp = 3'b010;
				else if (Function == 5'b00001) 
					ALUOp = 3'b000;
				else
					ALUOp = 3'b001;
				
		        R_mem = 1'b0; 
		        W_mem = 1'b0;
		        WB = 1'b1;
				push = 1'b0;
			end
				
			else begin  
				
				PCSrc1 = 1'b1;
				PCSrc0 = 1'b0;
			    RegWrite = 1'b0;
		        ALUSrc1 = 1'b0; 
				ALUSrc0 = 1'b0; 
				ALUOp = 3'b001;
		        R_mem = 1'b0; 
		        W_mem = 1'b0;
				push = 1'b0;
			end
				
		/// I-Type	 
		else if (Type == 2'b10) begin		
			
			if (Function == 5'b00000 || Function == 5'b00001) begin	   ///ANDI || ADDI
				
				PCSrc1 = 1'b1;
				PCSrc0 = 1'b0;
			    RegWrite = 1'b1;
		        ALUSrc1 = 1'b0; 
				ALUSrc0 = 1'b1; 
				
				if (Function == 5'b00000)
					ALUOp = 3'b010;
				else   
					ALUOp = 3'b000;
	
				
		        R_mem = 1'b0; 
		        W_mem = 1'b0;
		        WB = 1'b1;
				push = 1'b0;
			end
				
			else if (Function == 5'b00010) begin //LW  
				
				PCSrc1 = 1'b1;
				PCSrc0 = 1'b0;
			    RegWrite = 1'b1;
		        ALUSrc1 = 1'b0; 
				ALUSrc0 = 1'b1; 
				ALUOp = 3'b000;
		        R_mem = 1'b1; 
		        W_mem = 1'b0;
				push = 1'b0;  
				WB = 1'b0;
				push = 1'b0;
			end
			
			else if (Function == 5'b00011) begin //SW  
				
				PCSrc1 = 1'b1;
				PCSrc0 = 1'b0;
			    RegWrite = 1'b0;
		        ALUSrc1 = 1'b0; 
				ALUSrc0 = 1'b1; 
				ALUOp = 3'b000;
		        R_mem = 1'b0; 
		        W_mem = 1'b1;
				push = 1'b0;  
				push = 1'b0;
			end
				
			else if (Function == 5'b00100) begin //BEQ  
				
				PCSrc1 = 1'b0;
				PCSrc0 = 1'b0;
			    RegWrite = 1'b0;
		        ALUSrc1 = 1'b1; 
				ALUSrc0 = 1'b1; 
				ALUOp = 3'b001;
		        R_mem = 1'b0; 
		        W_mem = 1'b0; 
				push = 1'b0;  
			end
		end
			
			
		/// J-Type	 
		else if (Type == 2'b01) begin	
			
			if (Function == 5'b00000) begin	 // J
				
				PCSrc1 = 1'b0;
				PCSrc0 = 1'b1;
			    RegWrite = 1'b0;
	             R_mem = 1'b0; 
		        W_mem = 1'b0;
			    push = 1'b0;
			end
			
			else begin	 // JAL
				
				PCSrc1 = 1'b0;
				PCSrc0 = 1'b1;
			    RegWrite = 1'b0;
		        R_mem = 1'b0; 
		        W_mem = 1'b0;
				push = 1'b1;
			end	 
			
		end
			
		else begin/// S-Type
					
			if (Function == 5'b00000 || Function == 5'b00001) begin	   ///SLL || SLR
				
				PCSrc1 = 1'b1;
				PCSrc0 = 1'b0;
			    RegWrite = 1'b1;
		        ALUSrc1 = 1'b1; 
				ALUSrc0 = 1'b0; 
				
				if (Function == 5'b00000)
					ALUOp = 3'b101;
				else   
					ALUOp = 3'b110;
	
		        R_mem = 1'b0; 
		        W_mem = 1'b0;
		        WB = 1'b1;
			    push = 1'b0;
			end
	
			else begin 
				
				PCSrc1 = 1'b1;
				PCSrc0 = 1'b0;
			     RegWrite = 1'b1;
		         ALUSrc1 = 1'b0; 
				ALUSrc0 = 1'b0; 
				
				if (Function == 5'b00010)
					ALUOp = 3'b101;
				else   
					ALUOp = 3'b110;
	
		        R_mem = 1'b0; 
		        W_mem = 1'b0;
		        WB = 1'b1;
			    push = 1'b0; 
			end
		end	 
	  end
	  	  
	  

	else if (current_state == 1) begin
		
		
		///Getting the values of the extenders
		immediate14 = IR[16:3];
		extended_immediate14 = {18'b000000000000000000, immediate14}; ///Temp, we want to change these 0's later on
		
		//$display ("extended_immediate14 = %b", extended_immediate14);
		
		immediate24 = IR[26:3];
		extended_immediate24 = {8'b00000000, immediate24}; ///Temp, we want to change these 0's later on  

			
		Registers[0] = 32'h00000008;				//0001 1000 0000 0010 1000 0000 0000 0110
		Registers[1] = 32'h00000007;
		Registers[8] = 32'h00000002;								   
			
		///Getting the addresses for the registers
		AddressOfRs1 = IR[26:22]; // (Rs1) Register 1 address for read operation	
		AddressOfRs2 = IR[16:12]; // (Rs2) Register 2 address for read operation  
		AddressOfRd = IR[21:17]; // (Rd) Register address for write operation 
			
		$display (PC);
		//$display ("%b", IR);
		//$display ("\n");
			

		Rs1 = Registers[AddressOfRs1];
		Rs2 = Registers[AddressOfRs2];
		Rd = Registers[AddressOfRd];  
		

		///Choose a value for the mux
			
	    case ({ALUSrc1, ALUSrc0})
	      2'b00: Y = Rs2;
	      2'b01: Y = extended_immediate14; //Output of the Extender 14
	      2'b10: Y = shiftAmount; //Output of the shift amount
	      2'b11: Y = Rd;
	    endcase	 
		
		//$display(Y); 
		
		
		/// Check if the Current instruction is Jump (J)
		if (Type == 2'b01 && Function == 5'b00000) begin
			
			current_state = 4;
			
			///Modify the PC to the Jump address
			outputOfUpAdder = PC + extended_immediate24;  
			PC =  outputOfUpAdder;
			
		end
		
		
		/// Check if the Current instruction is Jal 
		if (Type == 2'b01 && Function == 5'b00001) begin
			
			current_state = 4;
		
		    empty = (top == 0);
   		    full = (top == STACK_DEPTH);
			   
			   
			  // Push operation
		       if (push && !pop && !full) begin 	 
		          stack[top] = PC; 
				  top = top + 1;
		      end

			  ///Modify the PC
			  PC = PC +  extended_immediate24;
	   end	 
	   
	  // $display (stack[0]);
		
	end		   
	
	
	else if (current_state == 2)  begin
		
		operandA = Rs1;
		operandB = Y; //Output of the previous mux4x1  
		
		//$display ("extended_immediate14 = %b", extended_immediate14);
		
	case(ALUOp)
	    3'b000: outputOfALU = operandA + operandB;     // Addition
	    3'b001: outputOfALU = operandA - operandB;     // Subtraction
	    3'b010: outputOfALU = operandA & operandB;     // Bitwise AND
	    3'b011: outputOfALU = operandA | operandB;     // Bitwise OR
	    3'b100: outputOfALU = operandA ^ operandB;     // Bitwise XOR
	    3'b101: outputOfALU = operandA << operandB;    // Shift left (logical)
	    3'b110: outputOfALU = operandA >> operandB;    // Shift right (logical)
	    3'b111: outputOfALU = operandA >>> operandB;   // Shift right (arithmetic)
	    default: outputOfALU = 32'b0;                   // Default case: result is 0
	  endcase
	  
	  
	  
	  
	 ///We want later on to check if the last instruction is BEQ or CMP~~~~~~~~~~~~~~~~
	//----------------------------------------------------
	
	
	
	zero = (outputOfALU == 32'b0);  // Set zero flag if the result is zero 
	//$display (zero);
		
	///Check the current instruction is CMP or not
	if (Type == 2'b00 && Function == 5'b00011)  begin
		PC = PC + 1;
		current_state = 4;
	end	 
	
	///We want here to check the BEQ
	if (Type == 2'b10 && Function == 5'b00100)  begin	 
		if (zero == 1) begin
			//Modify the BTA  
			
			current_state = 4; 
			
			 ///Output of the Branch Target Address
			 outputOfBTA = PC + extended_immediate14;
			 
			 ///Modify the PC to the Branch Target Address
			 PC =  outputOfBTA;

		end
		
		else begin
			///The two numbers are not equal
			PC = PC + 1;
			current_state = 4;
		end
			
	end

end		 


	else if (current_state == 3) begin
		
		
		address	= outputOfALU; /// Address of the memory
		data_in	= Rd; // Store Instruction 
		
		if(W_mem && !R_mem) begin 
			
			 /// Store Instruction
			 data_memory[address] = data_in; 
			 outputOfTheStore = data_memory[address]; 
			 //$display ("data_memory[%d] = %d", address, outputOfTheStore);
			 
		end
			 
		else if(!W_mem && R_mem) begin	
		
			/// Load Instruction	 
		   	 data_memory[14] = 32'h00000009;
			 data_out = data_memory[address]; 
			 
		end	
		
		///Check the current instruction is Store or not
		if (Type == 2'b10 && Function == 5'b00011) begin  
			
			current_state = 4; 
			
			///check if the current instruction is the last instruction in the function
					
				///Here is the code to choose the correct value for the PC
					
					
		///Stack Part	
   		 empty = (top == 0);
   		 full = (top == STACK_DEPTH);
  	
		 // Pop operation
		 if (pop && !push && !empty) begin 
			 
	          top = top - 1;  // Move the top pointer down 	
			  outputOfStack = stack[top];
			  
			 PC = outputOfStack;
		     PC = PC + 1;
	      end

		  else PC = PC + 1;	
			  
	   end
   end   
	 
	 
	 else if (current_state == 4) begin
		 
		 //$display ("Data out = %d", data_out);
		 if (WB == 1) 
			 outOfDownMux = outputOfALU;
		 else
			 outOfDownMux = data_out;	

		 /// Write back to the destination Register
		if (RegWrite) begin
			Rd = outOfDownMux;
			Registers [AddressOfRd] = Rd;  
		end

		///Here is the code to choose the correct value for the PC 	 
		//$display(PC);
		///Stack Part	
   		 empty = (top == 0);
   		 full = (top == STACK_DEPTH);
  	
		 // Pop operation
		 if (pop && !push && !empty) begin 
			 
	          top = top - 1;  // Move the top pointer down 	
			  outputOfStack = stack[top];
			  
			 PC = outputOfStack;
		     PC = PC + 1;
	      end

		  else PC = PC + 1;
  
  end 


endmodule 


module TestBench ();
	
	reg clk;
	reg reset;	  
	
	///Instruction Decode Part
	wire [31:0] Rs1; // (Bus A )Output data from register 1
    wire [31:0] Rs2; // (Bus B) Output data from register 2
    wire [31:0] Rd; // Rd
	
	///Control Unit Part 
	wire PCSrc1;
	wire PCSrc0;
	wire RegWrite;
	wire ALUSrc1;
	wire ALUSrc0;
	wire [2:0]ALUOp;
	wire R_mem;
	wire W_mem;
	wire WB;
	wire push;
	wire pop;
	wire [31:0]outputOfALU;	 
	wire [31:0]extended_immediate14; 
	wire [31:0]extended_immediate24;
	wire [31:0]outputOfTheStore;  
	wire [4:0]shiftAmount;

AllTheSystem WS (clk, reset, PCSrc1, PCSrc0, RegWrite, ALUSrc1, ALUSrc0, ALUOp,R_mem, W_mem, WB, push, pop, Rs1, Rs2, Rd, outputOfALU, extended_immediate14, extended_immediate24, outputOfTheStore, shiftAmount);

initial begin current_state = 0; clk = 0; reset = 1; #1ns reset = 0; end  
	
//always @ (posedge clk) $display (current_state);
	
always #2ns clk = ~clk;  
   
initial #200ns $finish;
	
endmodule