----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:38:58 12/01/2008 
-- Design Name: 
-- Module Name:    eval_ctrl - Behavioral 
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

entity eval_ctrl is
generic (
	DATA_WIDTH 	: integer := 32; 	-- Natural register size
	P_UNITS 	: integer := 8  	-- Number of processing units
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
	sw_addr_cmd 		: out std_logic_vector(P_UNITS-1 downto 0);
	sw_addr_cmd_we 		: out std_logic;

	--sw_ffin_data 	: in std_logic_vector(DATA_WIDTH-1 downto 0);
	sw_ffin_full 	: in std_logic;
	sw_ffin_empty 	: in std_logic;
	sw_ffin_re 		: out std_logic;

	--sw_ffout_data 	: out std_logic_vector(DATA_WIDTH-1 downto 0);
	sw_ffout_full 	: in std_logic;
	sw_ffout_empty 	: in std_logic;
	sw_ffout_we 	: out std_logic;

	-- Order_perm interface
	ord_reset 	: out std_logic;
	ord_done 	: in std_logic;
	ord_enable 	: out std_logic; -- TODO: Add ord_enable to ord_perm module

	-- Eval interface
	ev_reset 		: out std_logic;
	ev_enable 		: out std_logic;
	ev_dest_load 	: out std_logic;
	ev_iter 		: out std_logic_vector(P_UNITS-1 downto 0);

	-- Mem interface
	mm_re 		: out std_logic;
	--mm_addr 	: out std_logic;
	mm_ctrl_ord : out std_logic
);
	
end eval_ctrl;

architecture Behavioral of eval_ctrl is
	
	type state_type is (S0_RESET, S1_PERM_ASK, S2_PERM_WAIT, S3_PERM_ORD,
		S4_LDEV_RESET, S5_LDEV_LOAD, S6_EV_RESET, S7_EV_ASK, S8_EV_WAIT,
		S9_EV_DO, SA_REP_RESET, SB_REP_FILL, SC_REP_ASK, SD_REP_WAIT,
		SE_DONE, SF_EV_NCOL);

	signal pstate 	: state_type;
	signal nstate 	: state_type;

	signal cont 	: std_logic_vector(P_UNITS-1 downto 0);
	signal columns 	: std_logic_vector(P_UNITS-1 downto 0);
	constant LAST 	: std_logic_vector(P_UNITS-1 downto 0) := (others => '1');

begin

	-- State Machine
	SM:process (clk) begin
		if (clk = '1' and clk'event) then
			if (reset = '1') then
				pstate <= S0_RESET;
			else
				pstate <= nstate;
			end if;
		end if;
	end process;

	-- Control flow
	nstate <= S0_RESET 		when ((pstate = S0_RESET and sw_start = '0') 
					or (pstate = SE_DONE)) else
			  S1_PERM_ASK	when ((pstate = S0_RESET and sw_start = '1')
					or (pstate = S3_PERM_ORD and ord_done = '0')) else
			  S2_PERM_WAIT	when ((pstate = S1_PERM_ASK)
					or (pstate = S2_PERM_WAIT and sw_ffin_full = '0')) else
			  S3_PERM_ORD	when ((pstate = S2_PERM_WAIT)
					or (pstate = S3_PERM_ORD and sw_ffin_empty = '0')) else
			  S4_LDEV_RESET	when (pstate = S3_PERM_ORD and sw_ffin_empty = '1') else
			  S5_LDEV_LOAD	when ((pstate = S4_LDEV_RESET)
					or (pstate = S5_LDEV_LOAD and cont /= LAST)) else
			  S6_EV_RESET	when (pstate = S5_LDEV_LOAD and cont = LAST) else
			  S7_EV_ASK		when ((pstate = S6_EV_RESET)
					or (pstate = S9_EV_DO and sw_ffin_empty = '1' and cont /= LAST)) else
			  S8_EV_WAIT	when ((pstate = S7_EV_ASK)
					or (pstate = S8_EV_WAIT and sw_ffin_full = '0')) else
			  S9_EV_DO		when ((pstate = S8_EV_WAIT and sw_ffin_full = '1')
					or (pstate = S9_EV_DO and sw_ffin_empty = '0')) else
			  SA_REP_RESET	when (pstate = S9_EV_DO and sw_ffin_empty = '1'
			  and cont = LAST and columns = LAST) else
			  SB_REP_FILL	when ((pstate = SA_REP_RESET)
				  or (pstate = SB_REP_FILL and sw_ffout_full = '0' and cont /= LAST)) else
			  SC_REP_ASK	when (pstate = SB_REP_FILL and sw_ffout_full = '1') else
			  SD_REP_WAIT	when ((pstate = SC_REP_ASK)
					or (pstate = SD_REP_WAIT and sw_ffout_empty = '0')) else
			  SE_DONE		when (pstate = SD_REP_WAIT and sw_ffout_empty = '1') else
			  SF_EV_NCOL 	when (pstate = S9_EV_DO and columns /= LAST
				  and cont = LAST) else
			  S0_RESET;

	-- Outputs
	sw_start_r <= '1' when (pstate = S1_PERM_ASK) else
				  '0';

	sw_done <= '1' when (pstate = SE_DONE) else
			   '0';

	sw_set_res <= '1' when (pstate = SC_REP_ASK) else
				  '0';

	sw_get_perm_batch <= '1' when (pstate = S1_PERM_ASK) else
						 '0';

	sw_get_table_batch <= '1' when (pstate = S7_EV_ASK) else
						  '0';

	sw_addr_cmd_we <= '1' when (pstate = S1_PERM_ASK or pstate = S7_EV_ASK) else
					  '0';
	
	sw_addr_cmd <= cont;

	sw_ffin_re <= '1' when (pstate = S3_PERM_ORD or pstate = S9_EV_DO) else
				  '0';

	sw_ffout_we <= '1' when (pstate = SB_REP_FILL) else
				   '0';

	ord_reset <= '1' when (pstate = S0_RESET) else
				 '0';

	ord_enable <= '1' when (pstate = S3_PERM_ORD) else
				  '0';

	ev_reset <= '1' when (pstate = S0_RESET) else
				'0';

	ev_enable <= '1' when (pstate = S5_LDEV_LOAD or pstate = S9_EV_DO) else
				 '0';

	ev_dest_load <= '1' when (pstate = S5_LDEV_LOAD) else
					'0';

	ev_iter <= cont;

	mm_re <= '1' when (pstate = S5_LDEV_LOAD) else
			 '0';
	
	mm_ctrl_ord <= '1' when (pstate = S5_LDEV_LOAD) else
				   '0';
	
	CNT:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (reset = '1' or pstate = S0_RESET or pstate = S4_LDEV_RESET
			or pstate = S6_EV_RESET or pstate = SA_REP_RESET) then
				cont <= (others => '0');
			elsif (pstate = S3_PERM_ORD or pstate = S5_LDEV_LOAD
			or pstate = S9_EV_DO or pstate = SB_REP_FILL) then
				cont <= cont + 1;
			end if;
		end if;
	end process;


end Behavioral;

