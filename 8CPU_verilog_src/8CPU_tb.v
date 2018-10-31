//`timescale 1ns/1ps

module CPU_tb ();

	reg clk;
	reg rst;

	initial begin
		$dumpvars;

		clk = 0;
		rst = 0;

		#100 rst = 1;
		#100000 $finish;
	end

	always #20 clk = !clk;

	CPU cpu_dut(.clk(clk), .reset(rst));
endmodule