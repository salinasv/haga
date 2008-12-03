----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:43:06 09/28/2008 
-- Design Name: 
-- Module Name:    eval_pool - Behavioral 
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

entity eval_pool is
generic (
	DATA_WIDTH	: integer:=32; -- Natural register size
	P_UNITS		: integer:=8  -- Number of processing units
);
port (
	--control
	clk			: in std_logic;
	reset		: in std_logic;

	enable 		: in std_logic;
	dest_load	: in std_logic;

	-- data
	Iter		: in std_logic_vector(P_UNITS-1 downto 0);
	Current		: in std_logic_vector(DATA_WIDTH-1 downto 0);
	Dest_in		: in std_logic_vector(P_UNITS-1 downto 0);

	--output
	Sum		: out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end eval_pool;

architecture Behavioral of eval_pool is

	COMPONENT eval_module
	GENERIC (
		DATA_WIDTH	: integer;	-- Natural register size
		P_UNITS		: integer	-- Number of processing units
	);
	PORT(
		clk			: in std_logic;
		reset		: in std_logic;

		enable 		: in std_logic;
		dest_load	: in std_logic;

		Iter		: in std_logic_vector(P_UNITS-1 downto 0);
		Current		: in std_logic_vector(DATA_WIDTH-1 downto 0);
		dest_in		: in std_logic_vector(P_UNITS-1 downto 0);

		Dest_out	: out std_logic_vector(P_UNITS-1 downto 0);
		Sum_out		: out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
	END COMPONENT;

	constant LAST : integer := (2**P_UNITS)-1;

	type bus_type is array (2**P_UNITS-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
	type dest_type is array (2**P_UNITS-1 downto 0) of std_logic_vector(P_UNITS-1 downto 0);

	signal Sum_bus : bus_type;
	signal dest_array : dest_type;

begin

	Inst_eval_module_0: eval_module
	GENERIC MAP(
		DATA_WIDTH => DATA_WIDTH,
		P_UNITS => P_UNITS
	)
	PORT MAP(
		clk 		=> clk,
		reset		=> reset,
		enable 		=> enable,
		dest_load 	=> dest_load,
		Iter 		=> Iter,
		Current 	=> Current,
		dest_in 	=> dest_array(0),
		Dest_out 	=> open,
		Sum_out 	=> sum_bus(0)
	);

	Eval:for i in 1 to (2**P_UNITS)-2 generate
	begin
		Inst_eval_module_i: eval_module
		GENERIC MAP(
			DATA_WIDTH => DATA_WIDTH,
			P_UNITS => P_UNITS
		)
		PORT MAP(
			clk 		=> clk,
			reset		=> reset,
			enable 		=> enable,
			dest_load 	=> dest_load,
			Iter 		=> Iter,
			Current 	=> Current,
			dest_in 	=> dest_array(i),
			Dest_out 	=> dest_array(i - 1),
			Sum_out 	=> sum_bus(i)
		);
	end generate;

	Inst_eval_module_LAST: eval_module
	GENERIC MAP(
		DATA_WIDTH => DATA_WIDTH,
		P_UNITS => P_UNITS
	)
	PORT MAP(
		clk 		=> clk,
		reset		=> reset,
		enable 		=> enable,
		dest_load 	=> dest_load,
		Iter 		=> Iter,
		Current 	=> Current,
		dest_in 	=> dest_array(LAST),
		Dest_out 	=> dest_array(LAST - 1),
		Sum_out 	=> sum_bus(LAST)
	);

	-- Connect the input to the chain
	dest_array(LAST) <= dest_in;

	-- Great mux
	Sum <= sum_bus(conv_integer(Iter));

end Behavioral;
