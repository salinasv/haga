----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:38:12 09/27/2008 
-- Design Name: 
-- Module Name:    eval_module - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--use IEEE.math_real.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity eval_module is
generic (
	DATA_WIDTH	: integer := 32;	-- Natural register size
	P_UNITS		: integer := 8	-- Number of processing units
);
Port (
	-- Control
	clk			: in std_logic;
	reset		: in std_logic;

	dest_load	: in std_logic;

	-- Data
	Iter		: in std_logic_vector(P_UNITS-1 downto 0);
	Current		: in std_logic_vector(DATA_WIDTH-1 downto 0);
	dest_in		: in std_logic_vector(P_UNITS-1 downto 0);

	Dest_out	: out std_logic_vector(P_UNITS-1 downto 0);
	Sum_out		: out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end eval_module;

architecture Behavioral of eval_module is

	signal acc	: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal dest_reg : std_logic_vector(P_UNITS-1 downto 0);
	signal sum_sig : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

	-- We want to know wich data we want to sum. We need to store it in the dest_reg.
	-- We also want to load serially the data to be able to avoid a big enabler.
	Enabler:process (clk) begin
		if (clk = '1' and clk'event) then
			--reset
			if (reset = '1') then
				dest_reg <= (others => '0');

			-- We are serially loading the destination to each module
			elsif (dest_load = '1') then
				dest_reg <= dest_in;
			end if;
		end if;
	end process;

	-- Add the current data in the bus with the accumulator
	sum_sig <= acc + current;

	-- Accumulator
	Eval:process (clk) begin
		if (clk = '1' and clk'event) then
			-- reset
			if (reset = '1') then
				acc <= (others => '0');

			-- Only load the acc when the data in the bus is the one we are looking for
			-- and we want to enable this ONLY when we are not loading the destination
			elsif (iter = dest_reg and dest_load = '0') then
				acc <= sum_sig;
			end if;
		end if;
	end process;

	-- Outputs
	dest_out <= dest_reg;

	Sum_out <= acc;

end Behavioral;

