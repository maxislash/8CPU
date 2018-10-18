/* 8-bit CPU - Von Neumann architecture - Verilog
 * Maxime Descos - descos.maxime@gmail.com
 */

module alu(
	input [3:0] op	,
	input [7:0] A 	,
	input [7:0] B 	,
	input [7:0] flags,
	output reg [7:0] C,
	output reg [7:0] newFlags);

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
	input clk,
	input rw,
	input [15:0] addr,
	input [7:0]	data,
	output reg [7:0] q);

	parameter	DATA_WIDTH = 8,
				ADDR_WIDTH = 8,
				RAM_DEPTH = 1 << ADDR_WIDTH;

	reg [DATA_WIDTH-1:0] mem[0:RAM_DEPTH-1];

	always @(posedge clk) begin
		if(rw) 
			mem[addr] =	data;
		else begin
			q = mem[addr];
		end
	end

endmodule

module control_unit(
	input clk,
	input rst,

	output reg [3:0] alu_op
	output reg [7:0] alu_a,
	output reg [7:0] alu_b,
	output reg [7:0] alu_flags,
	input [7:0]	alu_newFlags,
	input [7:0] alu_c,

	output reg mem_rw,
	output reg [15:0] mem_addr,
	output reg [7:0] mem_data,
	input [7:0] mem_Q
	);

	reg [7:0] CPU_registers[0:15];
	reg [3:0] CPU_state;
	reg [3:0] CPU_nextState;
	reg [15:0] CPU_instruction;
	reg [7:0] CPU_flags;
	reg [15:0] IP;

	reg [15:0] m_IP;

	reg [3:0] m_alu_op;
	reg [7:0] m_alu_a;
	reg [7:0] m_alu_b;
	reg [7:0] m_flags;

	reg [7:0] m_RegisterData;
	reg [4:0] m_RegisterAddr;

	reg m_mem_rw;
	reg [15:0] m_mem_addr;
	reg [7:0] m_mem_data;

	parameter	STATE_FETCH_LO		= 4'b0000,
				STATE_FETCH_LO_READ = 4'b0001,
				STATE_FETCH_HI		= 4'b0010,
				STATE_FETCH_HI_READ = 4'b0011,
				STATE_DECODE		= 4'b0100,
				STATE_EXE_ALU		= 4'b0101,
				STATE_EXE_JUMP		= 4'b0110,
				STATE_EXE_MOVE_RTR	= 4'b0111,
				STATE_EXE_MOVE_MTR	= 4'b1000,
				STATE_EXE_MOVE_RTM	= 4'b1001,
				STATE_EXE_MOVE_IMM	= 4'b1010;

	parameter	INSTR_ALU	= 4'b0000,
				INSTR_MOVE	= 4'b0001,
				INSTR_MOVEI = 4'b0010,
				INSTR_JUMP	= 4'b0100;


	always @(state or IP or mem_Q) begin

		// Default assignements
		m_mem_rw = 0;
		m_IP = IP;
		m_flags = CPU_flags;

		case(state)

			STATE_FETCH_LO: begin
				m_mem_addr = IP;
				nextState = STATE_FETCH_LO_READ;
			end

			STATE_FETCH_LO_READ: begin
				instruction[7:0] = mem_Q;
				nextState = STATE_FETCH_HI;
			end

			STATE_FETCH_HI: begin
				m_mem_addr = IP + 1;
				nextState = STATE_FETCH_HI_READ;
			end

			STATE_FETCH_HI_READ: begin
				instruction[15:8] = mem_Q;
				nextState = STATE_DECODE;
			end

			STATE_DECODE: begin
				case(instruction[15:12])

					INSTR_ALU: nextState = STATE_ALU;

					INSTR_MOVE: begin
						case(instruction[11:8])
							4'b0000: begin 			//reg to reg
								nextState = STATE_EXE_MOVE_RTR;
							end

							4'b0001: begin 			// mem to reg
								m_mem_addr = {registers[14], registers[15]};
								m_RegisterAddr = instruction[7:4];

								nextState = STATE_EXE_MOVE_MTR;
							end

							4'b0010: begin 			// reg to mem
								m_mem_rw = 1;
								m_mem_addr = {registers[14], registers[15]};
								m_mem_data = registers[instruction[7:4]];

								nextState = STATE_EXE_MOVE_RTM;
							end					
					end

					INSTR_MOVEI: nextState = STATE_MOVE_IMM;
					
					INSTR_JUMP: nextState = STATE_JUMP;
			end

			STATE_ALU: begin
				m_alu_op = instruction[11:8];
				m_alu_a = registers[instruction[7:4]];
				m_alu_b = registers[instruction[3:0]];
				
				m_RegisterData = alu_c;
				m_RegisterAddr = instruction[7:4];
				m_flags = alu_newFlags;

				m_IP = m_IP + 2;
				nextState = STATE_FETCH_LO;
			end

			STATE_EXE_MOVE_RTR: begin
				m_RegisterAddr = instruction[7:4];
				m_RegisterData = registers[instruction[3:0]];

				m_IP = m_IP + 2;
				nextState = STATE_FETCH_LO;
			end

			STATE_EXE_MOVE_MTR: begin 			
				m_mem_addr = {registers[14], registers[15]};
				m_RegisterAddr = instruction[7:4];

				m_RegisterData = mem_Q;

				m_IP = m_IP + 2;
				nextState = STATE_FETCH_LO;
			end

			STATE_EXE_MOVE_RTM: begin
				m_mem_rw = 1;
				m_mem_addr = {registers[14], registers[15]};
				m_mem_data = registers[instruction[7:4]];

				m_IP = m_IP + 2;
				nextState = STATE_FETCH_LO;
			end

			STATE_MOVE_IMM: begin
				m_RegisterAddr = instruction[11:8];
				m_RegisterData = instruction[7:0]

				m_IP = m_IP + 2;
				nextState = STATE_FETCH_LO;
			end

			STATE_JUMP: begin
				if(k[7]) next_IP = IP - ((~(k[6:0]) + 1) << 1);
 				else next_IP = IP + (k[6:0] << 1);
 				end
			end

		endcase
	end

endmodule