----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.02.2018 05:23:24
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( op : in STD_LOGIC_VECTOR (3 downto 0);
           A : in UNSIGNED (7 downto 0);
           B : in UNSIGNED (7 downto 0);
           flags : in STD_LOGIC_VECTOR (7 downto 0);
           C : out UNSIGNED (7 downto 0);
           newFlags : out STD_LOGIC_VECTOR (7 downto 0));
end ALU;

architecture Behavioral of ALU is

constant OP_ADD : std_logic_vector(3 downto 0):="0000";
constant OP_SUB : std_logic_vector(3 downto 0):="0001";
constant OP_AND : std_logic_vector(3 downto 0):="0010";
constant OP_OR : std_logic_vector(3 downto 0):="0011";
constant OP_XOR : std_logic_vector(3 downto 0):="0100";
constant OP_NOT : std_logic_vector(3 downto 0):="0101";
constant OP_CMP : std_logic_vector(3 downto 0):="0110";

constant EQ_BIT : std_logic_vector(3 downto 0):="0110";
constant GRT_BIT : std_logic_vector(3 downto 0):="0110";

signal result : UNSIGNED(7 downto 0) := (others => '0'); 

begin

    process(op, A, B)

    begin

        case op is
            when OP_ADD => result <= A + B;
            when OP_SUB => result <= A - B;
            when OP_AND => result <= A and B;
            when OP_OR  => result <= A or B;
            when OP_XOR => result <= A xor B;
            when OP_NOT => result <= not(A);
            when OP_CMP => result <= A + B;
            when others => result <= (others => '0');
        end case;
    end process;
    
C <= result;

end Behavioral;
