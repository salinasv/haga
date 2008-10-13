
--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:47:17 10/12/2008
-- Design Name:   eval_module
-- Module Name:   /home/salinasv/George/George/1Ise/Tesis/Xilinx/TSP_SEP_27/tb_eval_module.vhd
-- Project Name:  TSP_SEP_27
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: eval_module
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;
USE ieee.numeric_std.ALL;

ENTITY tb_eval_module_vhd IS
END tb_eval_module_vhd;

ARCHITECTURE behavior OF tb_eval_module_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT eval_module
	GENERIC (
		DATA_WIDTH	: integer := 32;	-- Natural register size
		P_UNITS		: integer := 8	-- Number of processing units
	);
	PORT(
		clk 		: IN std_logic;
		reset 		: IN std_logic;

		dest_load 	: IN std_logic;

		Iter 		: IN std_logic_vector(P_UNITS-1 downto 0);
		Current 	: IN std_logic_vector(DATA_WIDTH-1 downto 0);
		dest_in 	: IN std_logic_vector(P_UNITS-1 downto 0);          
                                                       
		Dest_out 	: OUT std_logic_vector(P_UNITS-1 downto 0);
		Sum_out 	: OUT std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	END COMPONENT;

	----- ports
	--Inputs
	SIGNAL clk :  std_logic := '0';
	SIGNAL reset :  std_logic := '0';
	SIGNAL dest_load :  std_logic := '0';
	SIGNAL Iter :  std_logic_vector(7 downto 0) := (others=>'0');
	SIGNAL Current :  std_logic_vector(31 downto 0) := (others=>'0');
	SIGNAL dest_in :  std_logic_vector(7 downto 0) := (others=>'0');

	--Outputs
	SIGNAL Dest_out :  std_logic_vector(7 downto 0);
	SIGNAL Sum_out :  std_logic_vector(31 downto 0);

	-- util
	signal T : time := 3.3 ns;

	signal pstate, nstate : integer range 0 to 4 := 0;
	signal cont : integer range 0 to 32 := 0;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: eval_module 
	GENERIC MAP(
		DATA_WIDTH	=> 32,	-- Natural register size
		P_UNITS		=> 8	-- Number of processing units
	)
	PORT MAP(
		clk => clk,
		reset => reset,
		dest_load => dest_load,
		Iter => Iter,
		Current => Current,
		dest_in => dest_in,
		Dest_out => Dest_out,
		Sum_out => Sum_out
	);

	-- clock generator.
	tb : PROCESS
	BEGIN
		wait for T/2;
		clk <= not clk;
	END PROCESS;


	-- State Machine
	SM:process (clk) begin
		if (clk = '1' and clk'event) then
			pstate <= nstate;
		end if;
	end process;

	nstate <= 	1 when (pstate = 0 or (pstate = 1 and cont < 10)) else
				2 when ((pstate = 1 and cont <= 10) or (pstate = 2 and cont < 20)) else
				3 when (pstate = 2) else
				4 when (pstate = 3 or pstate = 4) else
				0;

	-- cont
	CNT:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (pstate = 3 or pstate = 0) then
				cont <= 0;
			else
				cont <= cont + 1;
			end if;
		end if;
	end process;


	-- signals
	reset <= '1' when (pstate = 0) else
			'0';

	dest_load <= '1' when (pstate = 1) else
			  '0';

	current <= conv_std_logic_vector(10, 32);
	dest_in <= conv_std_logic_vector(cont + 5, 8) ;
	iter <= conv_std_logic_vector(cont,8);

END;
