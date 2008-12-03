----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:37:03 12/02/2008 
-- Design Name: 
-- Module Name:    bram_mod - Behavioral 
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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bram_mod is
	generic (
	DATA_WIDTH 		: integer := 32;
	ADDR_WIDTH 		: integer := 11
);
	port (
	clk 		: in std_logic;

	wr_en 		: in std_logic;

	data_in 	: in std_logic_vector(DATA_WIDTH-1 downto 0);
	data_out 	: out std_logic_vector(DATA_WIDTH-1 downto 0);

	addr 		: in std_logic_vector(ADDR_WIDTH-1 downto 0)
);
end bram_mod;

architecture Behavioral of bram_mod is

	type ram_type is array ((2**ADDR_WIDTH)-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);

	signal ram 	: ram_type;

begin

	RM:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (wr_en = '1') then
				ram(conv_integer(addr)) <= data_in;
			end if;
			data_out <= ram(conv_integer(addr));
		end if;
	end process;


end Behavioral;

