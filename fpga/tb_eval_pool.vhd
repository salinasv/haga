
--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   07:14:00 05/01/2002
-- Design Name:   eval_pool
-- Module Name:   /home/salinasv/src/Tesis/Xilinx/pbas/tb_eval_pool.vhd
-- Project Name:  pbas
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: eval_pool
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

ENTITY tb_eval_pool_vhd IS
END tb_eval_pool_vhd;

ARCHITECTURE behavior OF tb_eval_pool_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT eval_pool
	GENERIC (
		DATA_WIDTH	: integer:=32; -- Natural register size
		P_UNITS		: integer:=8  -- Number of processing Units
	);
	PORT (
		--control
		clk			: in std_logic;
		reset		: in std_logic;

		dest_load	: in std_logic;

		-- data
		Iter		: in std_logic_vector(P_UNITS-1 downto 0);
		Current		: in std_logic_vector(DATA_WIDTH-1 downto 0);
		Dest_in		: in std_logic_vector(P_UNITS-1 downto 0);

		--output
		Sum		: out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
	END COMPONENT;

	constant DATA_WIDTH : integer := 32;
	constant P_UNITS : integer := 8;
	constant LAST : integer := (2**P_UNITS)-1;

	--Inputs
	SIGNAL clk :  std_logic := '0';
	SIGNAL reset :  std_logic := '0';
	SIGNAL dest_load :  std_logic := '0';
	SIGNAL Iter :  std_logic_vector(P_UNITS-1 downto 0) := (others=>'0');
	SIGNAL Current :  std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
	SIGNAL Dest_in :  std_logic_vector(P_UNITS-1 downto 0) := (others=>'0');

	--Outputs
	SIGNAL Sum :  std_logic_vector(DATA_WIDTH-1 downto 0);

	signal T : time := 3.3 ns;

	signal pstate, nstate : integer range 0 to 5 := 0;
	signal cont : integer range 0 to LAST :=0;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: eval_pool 
	GENERIC MAP(
		DATA_WIDTH	=> DATA_WIDTH,
		P_UNITS		=> P_UNITS
	)
	PORT MAP(
		clk 		=> clk,
		reset		=> reset,
		dest_load 	=> dest_load,
		Iter 		=> Iter,
		Current 	=> Current,
		Dest_in 	=> Dest_in,
		Sum 		=> Sum
	);

	tb : PROCESS
	BEGIN
		wait for T/2;
		clk <= not clk;
	END PROCESS;
	
	SM:process (clk)
	begin
		if (clk = '1' and clk'event) then
			pstate <= nstate;
		end if;
	end process;

	nstate <=	0 when (pstate = 4 and iter = 2**P_UNITS) else
		   		1 when (pstate = 0) else
				2 when (pstate = 1 or (pstate = 2 and iter < LAST)) else
				3 when (pstate = 2 and iter = LAST) else
				4 when (pstate = 3 or (pstate = 4 and iter < LAST)) else
				5 when ((pstate = 4 and iter = LAST) or (pstate = 5 and iter < LAST)) else
				0;

	CNT:process (clk)
	begin
		if (clk = '1' and clk'event) then
			--if (pstate = 0 or pstate =3 or cont = LAST) then
			if (cont = LAST or pstate = 0) then
				cont <= 0;
			else
				cont <= cont + 1;
			end if;
		end if;
	end process;

	dest_load <=	'1' when (pstate = 1 or pstate = 2) else
			  		'0';

	reset <=	'1' when (pstate = 0) else
		  		'0';

	iter <= conv_std_logic_vector(cont, P_UNITS);
	dest_in <= iter;
	current <= conv_std_logic_vector(cont, DATA_WIDTH) when (pstate /= 5) else
				(others => '0');

END;
