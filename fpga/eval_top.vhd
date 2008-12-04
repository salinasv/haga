----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:55:52 12/02/2008 
-- Design Name: 
-- Module Name:    eval_top - Behavioral 
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

entity eval_top is
generic (
	DATA_WIDTH 		: integer := 32;
	P_UNITS 		: integer := 8;
	FIFO_WIDTH 		: integer := 32;
	ADDR_WIDTH 		: integer := 11
);
port (
	clk 	: in std_logic;
	reset 	: in std_logic;

	-- Software interface
	sw_start 			: in std_logic;
	sw_start_r 			: out std_logic;
	sw_done 			: out std_logic;
	sw_set_res 			: out std_logic;
	sw_get_perm_batch 	: out std_logic;
	sw_get_table_batch 	: out std_logic;
	sw_addr_cmd 		: out std_logic_vector(2*P_UNITS-1 downto 0);
	sw_addr_cmd_we 		: out std_logic;

	sw_ffin_full 	: in std_logic;
	sw_ffin_empty 	: in std_logic;
	sw_ffin_re 		: out std_logic;
	sw_ffin_data 	: in std_logic_vector(DATA_WIDTH-1 downto 0);

	sw_ffout_full 	: in std_logic;
	sw_ffout_empty 	: in std_logic;
	sw_ffout_we 	: out std_logic;
	sw_ffout_data 	: out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end eval_top;

architecture Behavioral of eval_top is

	component eval_ctrl
	generic (
		DATA_WIDTH 	: integer; 	-- Natural register size
		P_UNITS 	: integer  	-- Number of processing units
	);
		port (
		clk 	: in std_logic;
		reset 	: in std_logic;

		-- Software interface
		sw_start 			: in std_logic;
		sw_start_r 			: out std_logic;
		sw_done 			: out std_logic;
		sw_set_res 			: out std_logic;
		sw_get_perm_batch 	: out std_logic;
		sw_get_table_batch 	: out std_logic;
		sw_addr_cmd 		: out std_logic_vector(2*P_UNITS-1 downto 0);
		sw_addr_cmd_we 		: out std_logic;

		sw_ffin_full 	: in std_logic;
		sw_ffin_empty 	: in std_logic;
		sw_ffin_re 		: out std_logic;

		sw_ffout_full 	: in std_logic;
		sw_ffout_empty 	: in std_logic;
		sw_ffout_we 	: out std_logic;

		-- Order_perm interface
		ord_reset 	: out std_logic;
		ord_done 	: in std_logic;
		ord_enable 	: out std_logic;

		-- Eval interface
		ev_reset 		: out std_logic;
		ev_enable 		: out std_logic;
		ev_dest_load 	: out std_logic;
		ev_iter 		: out std_logic_vector(P_UNITS-1 downto 0);

		-- Mem interface
		mm_re 		: out std_logic;
		mm_ctrl_ord : out std_logic
	);
	end component;

	component eval_pool
	generic (
		DATA_WIDTH	: integer; -- Natural register size
		P_UNITS		: integer  -- Number of processing units
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
	end component;

	component order_perm
		generic (
			DATA_WIDTH	: integer;	-- natural register size
			M_LOG2		: integer		-- log2(m)
		);
		Port (
		clk		: in std_logic;
		Dat_in	: in std_logic_vector(M_LOG2-1 downto 0);
		reset	: in std_logic;
		enable 	: in std_logic;

		Datram	: out std_logic_vector(M_LOG2-1 downto 0);
		addr	: out std_logic_vector(M_LOG2-1 downto 0);
		WE		: out std_logic;
		Done	: out std_logic
		);
	end component;

	component bram_mod
	generic (
		DATA_WIDTH 		: integer;
		ADDR_WIDTH 		: integer
	);
	port (
		clk 		: in std_logic;

		wr_en 		: in std_logic;

		data_in 	: in std_logic_vector(DATA_WIDTH-1 downto 0);
		data_out 	: out std_logic_vector(DATA_WIDTH-1 downto 0);

		addr 		: in std_logic_vector(ADDR_WIDTH-1 downto 0)
	);
	end component;

	signal ord_reset 	: std_logic;
	signal ord_done 	: std_logic;
	signal ord_enable 	: std_logic;
	signal ord_we 		: std_logic;
	signal ord_ram_dat 	: std_logic_vector(P_UNITS-1 downto 0);
	signal ord_ram_addr : std_logic_vector(P_UNITS-1 downto 0);

	signal ev_reset 	: std_logic;
	signal ev_enable 	: std_logic;
	signal ev_dest_load : std_logic;
	signal ev_iter 		: std_logic_vector(P_UNITS-1 downto 0);
	signal ev_sum 		: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal mm_re 		: std_logic;
	--signal mm_we 		: std_logic;
	signal mm_ctrl_ord 	: std_logic;

	signal br_data_in 	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal br_data_out 	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal br_wr_en 	: std_logic;
	signal br_addr 		: std_logic_vector(ADDR_WIDTH-1 downto 0);

begin

	CTRL: eval_ctrl
	generic map(
		DATA_WIDTH 	=> DATA_WIDTH, 	-- Natural register size
		P_UNITS 	=> P_UNITS 	-- Number of processing units
	)
	port map(
		clk 	=> clk,
		reset 	=> reset,

		-- Software interface
		sw_start 			=> sw_start,
		sw_start_r 			=> sw_start_r,
		sw_done 			=> sw_done,
		sw_set_res 			=> sw_set_res,
		sw_get_perm_batch 	=> sw_get_perm_batch,
		sw_get_table_batch 	=> sw_get_table_batch,
		sw_addr_cmd 		=> sw_addr_cmd,
		sw_addr_cmd_we 		=> sw_addr_cmd_we,

		sw_ffin_full 	=> sw_ffin_full,
		sw_ffin_empty 	=> sw_ffin_empty,
		sw_ffin_re 		=> sw_ffin_re,

		sw_ffout_full 	=> sw_ffout_full,
		sw_ffout_empty 	=> sw_ffout_empty,
		sw_ffout_we 	=> sw_ffout_we,

		-- Order_perm interface
		ord_reset 	=> ord_reset,
		ord_done 	=> ord_done,
		ord_enable 	=> ord_enable,

		-- Eval interface
		ev_reset 		=> ev_reset,
		ev_enable 		=> ev_enable,
		ev_dest_load 	=> ev_dest_load,
		ev_iter 		=> ev_iter,

		-- Mem interface
		mm_re 		=> mm_re,
		mm_ctrl_ord => mm_ctrl_ord
	);

	EP: eval_pool
	generic map(
		DATA_WIDTH	=> DATA_WIDTH, -- Natural register size
		P_UNITS		=> P_UNITS  -- Number of processing units
	)
	port map(
		--control
		clk			=> clk,
		reset		=> ev_reset,

		enable 		=> ev_enable,
		dest_load	=> ev_dest_load,

		-- data
		Iter		=> ev_iter,
		Current		=> sw_ffin_data,
		Dest_in		=> br_data_out(P_UNITS-1 downto 0),

		--output
		Sum			=> ev_sum
	);

	OP:order_perm
	generic map(
		DATA_WIDTH	=> DATA_WIDTH,	-- natural register size
		M_LOG2		=> P_UNITS	-- log2(m)
	)
	Port map(
		clk		=> clk,
		Dat_in	=> sw_ffin_data(P_UNITS-1 downto 0),
		reset	=> ord_reset,
		enable 	=> ord_enable,

		Datram	=> ord_ram_dat,
		addr	=> ord_ram_addr,
		WE		=> ord_we,
		Done	=> ord_done
	);

	BRAM:bram_mod
	generic map(
		DATA_WIDTH 		=> DATA_WIDTH,
		ADDR_WIDTH 		=> ADDR_WIDTH
	)
	port map(
		clk 		=> clk,

		wr_en 		=> br_wr_en,

		data_in 	=> br_data_in,
		data_out 	=> br_data_out,

		addr 		=> br_addr
	);

	br_addr(P_UNITS-1 downto 0) <= ev_iter when (mm_ctrl_ord = '1') else
			   ord_ram_addr;

	br_data_in(P_UNITS-1 downto 0) <= ord_ram_dat;
	br_wr_en <= mm_re when (mm_ctrl_ord = '1') else
				ord_we;
	sw_ffout_data <= ev_sum;

end Behavioral;

