----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:12:08 09/30/2008 
-- Design Name: 
-- Module Name:    order_perm - Behavioral 
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

entity order_perm is
	generic (
		DATA_WIDTH	: integer := 32;	-- natural register size
		M_LOG2		: integer := 8		-- log2(m)
	);
	Port (
	clk		: in std_logic;
	Dat_in	: in std_logic_vector(M_LOG2-1 downto 0);
	start	: in std_logic;
	reset	: in std_logic;

	-- Agregar este registro para meterle un delay y el dato esté a la par
	-- de la dirección donde queremos asignarlo.
	Datram	: out std_logic_vector(M_LOG2-1 downto 0);
	addr	: out std_logic_vector(M_LOG2-1 downto 0);
	WE		: out std_logic;
	Done	: out std_logic
	);
end order_perm;

architecture Behavioral of order_perm is

	signal perm_cont : std_logic_vector(M_LOG2-1 downto 0) := (others => '0');
	signal source	: std_logic_vector(M_LOG2-1 downto 0) := (others => '0');
	signal dest		: std_logic_vector(M_LOG2-1 downto 0);
	signal first	: std_logic_vector(M_LOG2-1 downto 0) := (others => '0');
	signal running	: std_logic := '0';
	signal done_reg	: std_logic_vector(1 downto 0) := (others => '0');

	constant NOT_ZERO : std_logic_vector(M_LOG2-1 downto 0) := (others => '1');

begin

	C1:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (reset = '1' or running = '0') then
				perm_cont <= (others => '0');
			else
				perm_cont <= perm_cont + 1;
			end if;
		end if;
	end process;

	RU:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (reset = '1' or done_reg(1) = '1')then
				running <= '0';
			else
				running <= '1';
			end if;
		end if;
	end process;

	D1:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (perm_cont = NOT_ZERO) then
				done_reg <= "10";
			else
				done_reg <= '0'&done_reg(1);
			end if;
		end if;
	end process;

	F1:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (reset = '1') then
				first <= (others => '0');
			elsif (running = '0') then
				first <= Dat_in;
			end if;
		end if;
	end process;

	-- Set the write enable after one clock cycle to avoid writing the first
	-- element in the address 0
	WrEn:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (reset = '1' or running = '0') then
				WE <= '0';
			else
				WE <= '1';
			end if;
		end if;
	end process;

	-- Do not set the output data when we have nota valid data, at the first
	-- read. Also, reset when we get 'start'
	DAT:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (reset = '1') then 
				dest <= (others => '0');
			elsif (perm_cont = NOT_ZERO) then
				dest <= first;
			else
				dest <= dat_in;
			end if;
		end if;
	end process;

	S1:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (reset = '1') then
				source <= (others => '0');
			elsif (running = '0') then
				source <= dat_in;
			else
				source <= dest;
			end if;
		end if;
	end process;

	addr <= source;
	datram <= dest;
	done <= done_reg(0);


end Behavioral;

