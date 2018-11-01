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
		newFlags = flags;
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

	initial begin
		mem[0] = 8'b00000000; mem[1] = 8'b00100000;
		mem[2] = 8'b00000001; mem[3] = 8'b00100001;
		mem[4] = 8'b00000011; mem[5] = 8'b00100011;
		mem[6] = 8'b00000001; mem[7] = 8'b00000000;
		mem[8] = 8'b00100000; mem[9] = 8'b00010000;
		mem[10] = 8'b00000001; mem[11] = 8'b00010000;
		mem[12] = 8'b00010010; mem[13] = 8'b00010000;
		mem[14] = 8'b00110001; mem[15] = 8'b00000110;
		mem[16] = 8'b11111011; mem[17] = 8'b01000011;	//jg
		mem[18] = 8'b00000000; mem[19] = 8'b00101110;
		mem[20] = 8'b00110010; mem[21] = 8'b00101111;
		mem[22] = 8'b00010000; mem[23] = 8'b00010010;
	end

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

	output reg [3:0] alu_op,
	output reg [7:0] alu_a,
	output reg [7:0] alu_b,
	output [7:0] alu_flags,
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
	reg [15:0] calc_IP;
	reg [7:0] m_instruction_lo;
	reg [7:0] m_instruction_hi;

	reg [3:0] m_alu_op;
	reg [7:0] m_alu_a;
	reg [7:0] m_alu_b;
	reg [7:0] m_flags;

	reg [7:0] m_RegisterData;
	reg [4:0] m_RegisterAddr;

	reg m_mem_rw;
	reg [15:0] m_mem_addr;
	reg [7:0] m_mem_data;

	parameter	STATE_FETCH_LO		= 4'b0000,  //0
				STATE_FETCH_LO_READ = 4'b0001,  //1
				STATE_FETCH_HI		= 4'b0010,  //2
				STATE_FETCH_HI_READ = 4'b0011,  //3
				STATE_DECODE		= 4'b0100,  //4
				STATE_EXE_ALU		= 4'b0101,  //5 
				STATE_EXE_JUMP		= 4'b0110,  //6
				STATE_EXE_MOVE_RTR	= 4'b0111,  //7 
				STATE_EXE_MOVE_MTR	= 4'b1000,  //8
				STATE_EXE_MOVE_RTM	= 4'b1001,  //9
				STATE_EXE_MOVE_IMM	= 4'b1010;  //a

	parameter	INSTR_ALU	= 4'b0000,
				INSTR_MOVE	= 4'b0001,
				INSTR_MOVEI = 4'b0010,
				INSTR_JUMP	= 4'b0100;

	parameter	JUMP				= 4'b0000,
				JUMP_IF_EQUAL 		= 4'b0001,
				JUMP_IF_NOT_EQUAL	= 4'b0010,
				JUMP_IF_GREATER 	= 4'b0011,
				JUMP_IF_NOT_GREATER	= 4'b0100;

	parameter	EQ_BIT	=	'd0,
				GRT_BIT	=	'd1;

	assign alu_flags = CPU_flags;

	always @(CPU_state or IP or mem_Q or CPU_instruction or CPU_registers or alu_c or alu_newFlags or CPU_flags) begin
        
		// Default assignements
		m_mem_rw = 0;
		m_IP = IP;
		m_flags = CPU_flags;
		m_instruction_lo = CPU_instruction[7:0];
		m_instruction_hi = CPU_instruction[15:8];

		case(CPU_state)

			STATE_FETCH_LO: begin
				m_mem_addr = m_IP;
				CPU_nextState = STATE_FETCH_LO_READ;
			end

			STATE_FETCH_LO_READ: begin
				#1 m_instruction_lo = mem_Q;
				CPU_nextState = STATE_FETCH_HI;
			end

			STATE_FETCH_HI: begin
				m_mem_addr = m_IP + 1;
				CPU_nextState = STATE_FETCH_HI_READ;
			end

			STATE_FETCH_HI_READ: begin
				#1 m_instruction_hi = mem_Q;
				CPU_nextState = STATE_DECODE;
			end

			STATE_DECODE: begin
				case(CPU_instruction[15:12])

					INSTR_ALU: CPU_nextState = STATE_EXE_ALU;

					INSTR_MOVE: begin
						case(CPU_instruction[11:8])
							4'b0000: begin 			//reg to reg
								CPU_nextState = STATE_EXE_MOVE_RTR;
							end

							4'b0001: begin 			// mem to reg
								m_mem_addr = {CPU_registers[14], CPU_registers[15]};
								m_RegisterAddr = CPU_instruction[7:4];

								CPU_nextState = STATE_EXE_MOVE_MTR;
							end

							4'b0010: begin 			// reg to mem
								m_mem_rw = 1;
								m_mem_addr = {CPU_registers[14], CPU_registers[15]};
								m_mem_data = CPU_registers[CPU_instruction[7:4]];

								CPU_nextState = STATE_EXE_MOVE_RTM;
							end	
						endcase				
					end

					INSTR_MOVEI: CPU_nextState = STATE_EXE_MOVE_IMM;
					
					INSTR_JUMP: CPU_nextState = STATE_EXE_JUMP;
				endcase
			end

			STATE_EXE_ALU: begin
				alu_op = CPU_instruction[11:8];
				alu_a = CPU_registers[CPU_instruction[7:4]];
				alu_b = CPU_registers[CPU_instruction[3:0]];
				
				m_RegisterData = alu_c;
				m_RegisterAddr = CPU_instruction[7:4];
				m_flags = alu_newFlags;

				m_IP = m_IP + 2;
				CPU_nextState = STATE_FETCH_LO;
			end

			STATE_EXE_MOVE_RTR: begin
				m_RegisterAddr = CPU_instruction[7:4];
				m_RegisterData = CPU_registers[CPU_instruction[3:0]];

				m_IP = m_IP + 2;
				CPU_nextState = STATE_FETCH_LO;
			end

			STATE_EXE_MOVE_MTR: begin 			
				m_mem_addr = {CPU_registers[14], CPU_registers[15]};
				m_RegisterAddr = CPU_instruction[7:4];

				m_RegisterData = mem_Q;

				m_IP = m_IP + 2;
				CPU_nextState = STATE_FETCH_LO;
			end

			STATE_EXE_MOVE_RTM: begin
				m_mem_rw = 1;
				m_mem_addr = {CPU_registers[14], CPU_registers[15]};
				m_mem_data = CPU_registers[CPU_instruction[7:4]];

				m_IP = m_IP + 2;
				CPU_nextState = STATE_FETCH_LO;
			end

			STATE_EXE_MOVE_IMM: begin
				m_RegisterAddr = CPU_instruction[11:8];
				m_RegisterData = CPU_instruction[7:0];

				m_IP = m_IP + 2;
				CPU_nextState = STATE_FETCH_LO;
			end

			STATE_EXE_JUMP: begin
				if(CPU_instruction[7]) calc_IP = m_IP - {8'b00000000, ((~CPU_instruction[6:0]) + 1'b1) << 1};
 				else calc_IP = m_IP + ((CPU_instruction[6:0]) << 1);	

 				m_IP = m_IP + 2;
				case(CPU_instruction[11:8])
					JUMP: begin
						m_IP = calc_IP;
					end

					JUMP_IF_EQUAL: begin
						if (CPU_flags[EQ_BIT]) m_IP = calc_IP;
					end

					JUMP_IF_NOT_EQUAL: begin
						if (!CPU_flags[EQ_BIT]) m_IP = calc_IP;
					end

					JUMP_IF_GREATER: begin
						if (CPU_flags[GRT_BIT]) m_IP = calc_IP;
					end

					JUMP_IF_NOT_GREATER: begin
						if (!CPU_flags[GRT_BIT]) m_IP = calc_IP;
					end
 				endcase
 				CPU_nextState = STATE_FETCH_LO;
			end

		endcase
	end

	integer i;

	always @(posedge clk) begin
		if (rst) begin
			// reset
			CPU_registers[0] <= 'd0; CPU_registers[1] <= 'd0;
			CPU_registers[2] <= 'd0; CPU_registers[3] <= 'd0;
			CPU_registers[4] <= 'd0; CPU_registers[5] <= 'd0;
			CPU_registers[6] <= 'd0; CPU_registers[7] <= 'd0;
			CPU_registers[8] <= 'd0; CPU_registers[9] <= 'd0;
			CPU_registers[10] <= 'd0; CPU_registers[11] <= 'd0;
			CPU_registers[12] <= 'd0; CPU_registers[13] <= 'd0;
			CPU_registers[14] <= 'd0; CPU_registers[15] <= 'd0;
			IP <= 16'h0000;
			CPU_flags <= 'd0;
			CPU_state <= 'd0;
			//CPU_nextState <= 'd0;
			mem_addr <= 'd0;
			mem_data <= 'd0;
			mem_rw <= 0;
			CPU_instruction <= 'd0;
			
		end
		else begin
			CPU_state <= CPU_nextState;
			CPU_flags <= m_flags;
			CPU_registers[m_RegisterAddr] <= m_RegisterData;
			IP <= m_IP;
			CPU_instruction[15:8] <= m_instruction_hi;
			CPU_instruction[7:0] <= m_instruction_lo;

			mem_rw <= m_mem_rw;
			mem_addr <= m_mem_addr;
			mem_data <= m_mem_data;

			//Simulation
			if (CPU_state == STATE_DECODE) begin
				$display("IP: %08X", IP);
				$display("Flags: %02X", CPU_flags);
				$display("Current Instruction: %04X", CPU_instruction);
				for (i = 0; i < 16; i = i + 1) $display("R%02d: %02X", i, CPU_registers[i]);
				$display("-----------------------\n");
			end

		end
	end

endmodule

// 8CPU top level
module CPU(
	input clk,
	input rst);

	wire [3:0] alu_op;
	wire [7:0] alu_a;
	wire [7:0] alu_b;
	wire [7:0] alu_c;
	wire [7:0] alu_flags;
	wire [7:0] alu_newFlags;
	wire mem_rw;
	wire [15:0] mem_addr;
	wire [7:0] mem_data;
	wire [7:0] mem_Q;

	control_unit cu(.clk(clk), .rst(rst), .alu_op(alu_op), .alu_a(alu_a), .alu_b(alu_b), .alu_flags(alu_flags), .alu_newFlags(alu_newFlags), .alu_c(alu_c), .mem_rw(mem_rw), .mem_addr(mem_addr), .mem_data(mem_data), .mem_Q(mem_Q));

	alu alu(.op(alu_op), .A(alu_a), .B(alu_b), .flags(alu_flags), .C(alu_c), .newFlags(alu_newFlags));

	mem mem(.clk(clk), .rw(mem_rw), .addr(mem_addr), .data(mem_data), .q(mem_Q));

endmodule