----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:42:19 11/18/2008 
-- Design Name: 
-- Module Name:    registers - Behavioral 
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

entity registers is
	generic (
	BAR_ADDR_WIDTH 	: integer := 11;
	BAR_EN_WIDTH 	: integer := 2
);
	port (
	reg_out : out std_logic_vector(7 downto 0);

	clk 	: in std_logic;
	rst_n 	: in std_logic;

	-- Read port
	rd_addr_i 	: in std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0);
	rd_be_i 	: in std_logic_vector(3 downto 0);
	rd_data_o 	: out std_logic_vector(31 downto 0);

	-- Write Port
	wr_addr_i 	: in std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0);
	wr_be_i 	: in std_logic_vector(7 downto 0);
	wr_data_i 	: in std_logic_vector(31 downto 0);
	wr_en_i 	: in std_logic;
	wr_busy_o 	: out std_logic
);
end registers;

architecture Behavioral of registers is

	constant BAR0 : std_logic_vector(BAR_EN_WIDTH-1 downto 0):= "00";
	--constant BAR0 : integer := 0;

	signal reg0 : std_logic_vector(31 downto 0) := x"AAAAAAAA";
--	signal reg0 : std_logic_vector(31 downto 0) := x"55555555";
	signal reg1 : std_logic_vector(31 downto 0);
	signal reg2 : std_logic_vector(31 downto 0);
	signal reg3 : std_logic_vector(31 downto 0);

	signal rd_aligned_data 	: std_logic_vector(31 downto 0);
	signal wr_aligned_data 	: std_logic_vector(31 downto 0);

begin

	reg_out <= reg0(7 downto 0);

	rd_data_o <= rd_aligned_data(7 downto 0) & rd_aligned_data(15 downto 8) &
				 rd_aligned_data(23 downto 16) & rd_aligned_data(31 downto 24);
	wr_aligned_data <= wr_data_i(7 downto 0) & wr_data_i(15 downto 8) &
				 wr_data_i(23 downto 16) & wr_data_i(31 downto 24);

	W0:process(clk)begin
		if (clk = '1' and clk'event) then
			-- We want this to be BAR0
			if (wr_addr_i((BAR_EN_WIDTH+BAR_ADDR_WIDTH)-1 downto BAR_ADDR_WIDTH) = BAR0) then
				if (wr_en_i = '1') then
					-- Reg0
					if (wr_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 0) then
							reg0 <= wr_aligned_data;
					elsif (wr_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 1) then
							reg1 <= wr_aligned_data;
					elsif (wr_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 2) then
							reg2 <= wr_aligned_data;
					elsif (wr_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 3) then
							reg3 <= wr_aligned_data;
					end if;
				end if;
			else
				reg0 <= (others => '1');
			end if;
		end if;
	end process;

	Rd:process(clk)
	begin
		if (clk = '1' and clk'event) then
			if (rd_addr_i((BAR_EN_WIDTH+BAR_ADDR_WIDTH)-1 downto BAR_ADDR_WIDTH) = BAR0) then
				if (rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 0) then
					rd_aligned_data <= reg0;
				elsif (rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 1) then
					rd_aligned_data <= reg1;
				elsif (rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 2) then
					rd_aligned_data <= reg2;
				elsif (rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 3) then
					rd_aligned_data <= reg3;
				else
					rd_aligned_data <= x"12345678";
				end if;
			else
				rd_aligned_data(31 downto BAR_EN_WIDTH+BAR_ADDR_WIDTH) <= (others => '0');
				rd_aligned_data(BAR_ADDR_WIDTH+BAR_EN_WIDTH-1 downto 0)  <= rd_addr_i;
			end if;
		end if;
	end process;

end Behavioral;

