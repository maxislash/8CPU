/* 8-bit CPU - Von Neumann architecture - Verilog
 * Maxime Descos - descos.maxime@gmail.com
 */

module alu(
	input [3:0] 	op	,
	input [7:0] 	A 	,
	input [7:0] 	B 	,
	input [7:0] 	flags,
	 output reg [7:0] 	C,
	 output reg [7:0] 	newFlags);

	reg [7:0]	C;
	reg [7:0] 	newFlags;

	parameter	ALU_OP_ADD	= 4'b0000,
				ALU_OP_SUB	= 4'b0001,
				ALU_OP_AND	= 4'b0010,
				ALU_OP_OR	= 4'b0011,
				ALU_OP_XOR	= 4'b0100,
				ALU_OP_NOT	= 4'b0101,
				ALU_OP_CMP	= 4'b0110;

	parameter	EQ_BIT	=	'd0,
				GRT_BIT	=	'd1;

	always @(op or A or B or flags) begin
		C = A;
		newFlags = Flags;
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
	 output reg [7:0]	q);

	reg [7:0]	q;

	parameter	DATA_WIDTH = 8,
				ADDR_WIDTH = 8,
				RAM_DEPTH = 1 << ADDR_WIDTH;

	reg [DATA_WIDTH-1:0]	mem[0:RAM_DEPTH-1];

	always @(posedge clk) begin
		if(rw) 
			mem[addr]	=	data;
		else begin
			q	=	mem[addr];
		end
	end

endmodule

module pc(
	input clk,
	input [1:0] op,
	input [7:0]	k,
	 output reg [15:0] addr_instr);

	reg [15:0]	next_addr;
	reg	[15:0]	addr_instr;

	parameter 	RESET		= 2'b00,
				NOTHING 	= 2'b01,
				INCREMENT 	= 2'b10,
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

module control_unit(
	input clk,
	output reg [1:0] op_pc,
	output reg [7:0] k,
	output reg [3:0] op_alu,
	output reg [7:0] a_alu,
	output reg [7:0] b_alu,
	output reg [7:0] flags,
	input [7:0]	newFlags,
	output reg rw,
	output reg [15:0] mem_addr,
	output reg [7:0] mem_data,
	input [7:0] q
	);

	reg [7:0] registers[0:15];

	reg [3:0] state;
	reg [3:0] nextState;

	reg [15:0] instruction;

	reg [1:0] m_op_pc,
	reg [7:0] m_k,
	reg [3:0] m_op_alu,
	reg [7:0] m_a_alu,
	reg [7:0] m_b_alu,
	reg [7:0] m_flags,
	reg m_rw,
	reg [15:0] m_mem_addr,
	reg [7:0] m_mem_data,

	parameter	STATE_INIT			= 4'b0000,
				STATE_FETCH_LO		= 4'b0001,
				STATE_FETCH_LO_READ	= 4'b0010,
				STATE_FETCH_HI		= 4'b0011,
				STATE_FETCH_HI_READ	= 4'b0100,
				STATE_DECODE		= 4'b0101,
				STATE_ALU			= 4'b0110,
				STATE_JUMP			= 4'b0111,
				STATE_MOVE_RTR		= 4'b1000,
				STATE_MOVE_MTR		= 4'b1001,
				STATE_MOVE_RTM		= 4'b1010,
				STATE_MOVE_IMM		= 4'b1011;

	always @(state or addr_instr or q) begin

		m_op_pc = 2'b01;
		m_k = 'd0;
		m_op_alu = instruction[11:8];
		m_a_alu = registers[instruction[7:4]];
		m_b_alu = registers[instruction[3:0]];
		m_flags = newFlags;
		m_rw = 1'b0;
		m_mem_data = 'd0;
		m_mem_addr =  registers[14:15];

		case(state)
			STATE_INIT: begin
				
			end

			STATE_FETCH_LO: begin
				op_pc = 2'b01;
				instruction[7:0] = q 
				nextState = STATE_FETCH_LO_READ;
			end
		endcase
	end

endmodule