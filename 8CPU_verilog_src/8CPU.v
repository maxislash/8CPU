/* 8-bit CPU - Von Neumann architecture - Verilog
 * Maxime Descos - descos.maxime@gmail.com
 */

module alu(
	input [3:0] 	op	,
	input [7:0] 	A 	,
	input [7:0] 	B 	,
	input [7:0] 	flags,
	output [7:0] 	C,
	output [7:0] 	newFlags);

	reg [7:0]	C;

	parameter	ALU_OP_ADD	= 4'b0000,
				ALU_OP_SUB	= 4'b0001,
				ALU_OP_AND	= 4'b0010,
				ALU_OP_OR	= 4'b0011,
				ALU_OP_XOR	= 4'b0100,
				ALU_OP_NOT	= 4'b0101,
				ALU_OP_CMP	= 4'b0110;

	parameter	EQ_BIT	=	'd0;
				GRT_BIT	=	'd1;

	always @(op or A or B or flags) begin
		C = A;
		flags = newFlags;
		case(op)
			ALU_OP_ADD	:	C =	A + B;
			ALU_OP_SUB	:	C = A - B;
			ALU_OP_AND	:	C = A & B;
			ALU_OP_OR	:	C = A | B;
			ALU_OP_XOR	:	C = A ^ B;
			ALU_OP_NOT	:	C = ~A;
			ALU_OP_CMP	:	begin
								newFlags[EQ_BIT] = (A == B);
								newFlags[GRT_BIT] = (A > B);
							end
		endcase

	end
endmodule



module mem(
	input	clk,
	input	rw,
	input [15:0]	addr,
	input [7:0]		data,
	output [7:0]	q,
	);

	reg [7:0]	q;

	parameter	DATA_WIDTH = 8;
				ADDR_WIDTH = 8;
				RAM_DEPTH = 1 << ADDR_WIDTH;

	reg [DATA_WIDTH-1:0]	mem[0:RAM_DEPTH-1];

	always @(posedge clk) begin
		if(rw) 
			mem[addr]	=	data;

		q	=	mem[addr];
		end
	end

endmodule

module pc(
	input clk,
	input [1:0} op,
	input [7:0]	k,
	output [15:0] addr_instr)

	reg [15:0]	next_addr;
	reg	[15:0]	addr_instr;

	parameter 	RESET		= 2'b00; 
				NOTHING 	= 2'b01;
				INCREMENT 	= 2'b10;
				JUMP 		= 2'b11;


	always @(posedge clk) begin
			addr_instr <= next_addr;
	end

	always @(op or k) begin
		case(op)
			RESET: 		next_addr = 'd0;
			NOTHING:	next_addr = addr_instr;
			INCREMENT:	next_addr = addr_instr + 2;
			JUMP: begin
					if(k[7]) begin
						next_addr = addr_instr - ((~(k[6:0]) + 1) << 1);
					end
					else
						next_addr = addr_instr + (k[6:0] << 1);
				end
		endcase
	end

endmodule