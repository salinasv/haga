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

	component eval_top
	generic (
		DATA_WIDTH 		: integer;
		P_UNITS 		: integer;
		FIFO_WIDTH 		: integer;
		ADDR_WIDTH 		: integer
	);
	port (
		clk 	: in std_logic;
		reset 	: in std_logic;

		-- Software interface
		sw_start 		: in std_logic;
		sw_start_r 			: out std_logic;
		sw_done 			: out std_logic;
		sw_set_res 			: out std_logic;
		sw_get_perm_batch 	: out std_logic;
		sw_get_table_batch 	: out std_logic;
		sw_addr_cmd 		: out std_logic_vector(P_UNITS-1 downto 0);
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
	end component;

	component srl_fifo_32
    generic (
				width : integer -- set to how wide fifo is to be
	);
    port(
        data_in      : in     std_logic_vector (width -1 downto 0);
        data_out     : out    std_logic_vector (width -1 downto 0);
        reset        : in     std_logic;
        write        : in     std_logic;
        read         : in     std_logic;
        full         : out    std_logic;
        half_full    : out    std_logic;
        data_present : out    std_logic;
        clk          : in     std_logic
    );
	end component;

	-- Evaluator parameters
	constant DATA_WIDTH : integer := 32;
	constant P_UNITS 	: integer := 8;
	constant ADDR_WIDTH : integer := 2*P_UNITS;

	-- FIFO parameters
	constant FIFO_WIDTH : integer := 128;

	constant BAR0 : std_logic_vector(BAR_EN_WIDTH-1 downto 0):= "00";
	--constant BAR0 : integer := 0;

	-- WRITE command register: each bit cleaned by eval module.
	signal reg0 : std_logic_vector(31 downto 0) := x"AAAAAAAA";
--	signal reg0 : std_logic_vector(31 downto 0) := x"55555555";

	-- READ ONLY command register, cleaned when software read it
	signal reg1 : std_logic_vector(31 downto 0);
	signal reg1_set : std_logic_vector(31 downto 0);
	signal reg2 : std_logic_vector(31 downto 0);
	signal reg3 : std_logic_vector(31 downto 0);


	-- Alias the command bits from reg0
	alias START_BIT : std_logic is reg0(0);

	-- Alias status bits and commands to software
	alias DONE_BIT 			: std_logic is reg1_set(0);
	alias SET_RESULT 		: std_logic is reg1_set(1);
	alias GET_PERM_BATCH 	: std_logic is reg1_set(2);
	alias GET_TABLE_BATCH 	: std_logic is reg1_set(3);
	alias FIFO_TO_SW 		: std_logic_vector(DATA_WIDTH-1 downto 0) is reg2;
	alias FIFO_FROM_SW 		: std_logic_vector(DATA_WIDTH-1 downto 0) is reg3;

	signal rd_aligned_data 	: std_logic_vector(31 downto 0);
	signal wr_aligned_data 	: std_logic_vector(31 downto 0);
	signal rd_reg_data 		: std_logic_vector(31 downto 0);

	-- Eval signals
	--signal sw_start 			: std_logic;
	signal sw_start_r 			: std_logic;
	--signal sw_done 				: std_logic;
	--signal sw_set_res 			: std_logic;
	--signal sw_get_perm_batch 	: std_logic;
	--signal sw_get_table_batch 	: std_logic;
	signal sw_addr_cmd 			: std_logic_vector(P_UNITS-1 downto 0);
	signal sw_addr_cmd_we 		: std_logic;

	-- fifo signals
	signal sw_ffin_full 	: std_logic;
	signal sw_ffin_empty 	: std_logic;
	signal sw_ffin_empty_n 	: std_logic;
	signal sw_ffin_re 		: std_logic;
	signal sw_ffin_data 	: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal sw_ffout_full 	: std_logic;
	signal sw_ffout_empty 	: std_logic;
	signal sw_ffout_empty_n	: std_logic;
	signal sw_ffout_we 		: std_logic;
	signal sw_ffout_data 	: std_logic_vector(DATA_WIDTH-1 downto 0);

	signal ffin_we 		: std_logic;
	--signal ffin_we_q 	: std_logic;
	signal ffout_re 	: std_logic;
	signal ffout_re_q 	: std_logic;
	signal is_bar0 		: std_logic;

	signal rd_addr_q 	: std_logic_vector(BAR_EN_WIDTH+BAR_ADDR_WIDTH-1 downto 0);
	signal rd_addr_en 	: std_logic;

begin

	reg_out <= reg0(7 downto 0);

	rd_data_o <= rd_aligned_data(7 downto 0) & rd_aligned_data(15 downto 8) &
				 rd_aligned_data(23 downto 16) & rd_aligned_data(31 downto 24);

	wr_aligned_data <= wr_data_i(7 downto 0) & wr_data_i(15 downto 8) &
				 wr_data_i(23 downto 16) & wr_data_i(31 downto 24);

	rd_aligned_data <= rd_reg_data when (ffout_re_q = '1') else
					   sw_ffout_data;

	W0:process(clk)begin
		if (clk = '1' and clk'event) then
			-- We want this to be BAR0
			if (wr_addr_i((BAR_EN_WIDTH+BAR_ADDR_WIDTH)-1 downto BAR_ADDR_WIDTH) = BAR0) then
				if (wr_en_i = '1') then
					-- Reg0
					if (wr_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 0) then
							reg0 <= wr_aligned_data;
--					elsif (wr_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 1) then
--							reg1 <= wr_aligned_data;
					elsif (wr_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 2) then
							reg2 <= wr_aligned_data;
--					elsif (wr_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 3) then
--							reg3 <= wr_aligned_data;
					end if;
				end if;
			else
				reg0 <= (others => '1');
			end if;
		end if;
	end process;

	CMD_ADDR:process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (sw_addr_cmd_we = '1') then
				reg3(P_UNITS-1 downto 0) <= sw_addr_cmd;
			end if;
		end if;
	end process;

	Rd:process(clk)
	begin
		if (clk = '1' and clk'event) then
			if (rd_addr_i((BAR_EN_WIDTH+BAR_ADDR_WIDTH)-1 downto BAR_ADDR_WIDTH) = BAR0) then
				if (rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 0) then
					rd_reg_data <= reg0;
				elsif (rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 1) then
					rd_reg_data <= reg1;
				-- NOTE: reg2 is managed by fifo_out
				elsif (rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 3) then
					rd_reg_data <= reg3;
				else
					rd_reg_data <= x"12345678";
				end if;
			else
				rd_reg_data(31 downto BAR_EN_WIDTH+BAR_ADDR_WIDTH) <= (others => '0');
				rd_reg_data(BAR_ADDR_WIDTH+BAR_EN_WIDTH-1 downto 0)  <= rd_addr_i;
			end if;
		end if;
	end process;

	REG_1:
	for i in 0 to DATA_WIDTH-1 generate
	begin
		process (clk)
		begin
			if (clk = '1' and clk'event) then
				if (reg1_set(i) = '1') then
					reg1(i) <= '1';
				elsif (is_bar0 = '1'
				and rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 1
				and rd_addr_en = '1') then
					reg1(i) <= '0';
				end if;
			end if;
		end process;
	end generate;

	is_bar0 <= '1' when (rd_addr_i((BAR_EN_WIDTH+BAR_ADDR_WIDTH)-1 downto BAR_ADDR_WIDTH) = BAR0) else
			   '0';

	ffin_we <= '1' when (is_bar0 = '1' and rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 3) else
			   '0';

	ffout_re <= '1' when (is_bar0 = '1' and  rd_addr_i(BAR_ADDR_WIDTH-1 downto 2) = 2) else
				'0';

	sw_ffin_empty <= not sw_ffin_empty_n;
	sw_ffout_empty <= not sw_ffout_empty_n;

	-- Delay ff_out_re so we can enable the output mux between registers and fifo
	-- data when we have the real data from fifo_out
	FFO_RE:process (clk)
	begin
		if (clk = '1' and clk'event) then
			ffout_re_q <= ffout_re;
		end if;
	end process;

	-- Delay rd_addr_i to be able to know if there is some change
	-- and be able to use it as an rd_enable to reset the registers
	RD_AD:process (clk)
	begin
		if (clk = '1' and clk'event) then
			rd_addr_q <= rd_addr_i;
		end if;
	end process;

	rd_addr_en <= '1' when (rd_addr_i /= rd_addr_q) else
				  '0';

	EVAL: eval_top
	generic map(
		DATA_WIDTH 		=> DATA_WIDTH,
		P_UNITS 		=> P_UNITS,
		FIFO_WIDTH 		=> FIFO_WIDTH,
		ADDR_WIDTH 		=> ADDR_WIDTH
	)
	port map(
		clk 	=> clk,
		reset 	=> '0',

		-- Software interface
		sw_start 			=> START_BIT,
		sw_start_r 			=> sw_start_r,
		sw_done 			=> DONE_BIT,
		sw_set_res 			=> SET_RESULT,
		sw_get_perm_batch 	=> GET_PERM_BATCH,
		sw_get_table_batch 	=> GET_TABLE_BATCH,
		sw_addr_cmd 		=> sw_addr_cmd,
		sw_addr_cmd_we 		=> sw_addr_cmd_we,

		sw_ffin_full 	=> sw_ffin_full,
		sw_ffin_empty 	=> sw_ffin_empty,
		sw_ffin_re 		=> sw_ffin_re,
		sw_ffin_data 	=> sw_ffin_data,

		sw_ffout_full 	=> sw_ffout_full,
		sw_ffout_empty 	=> sw_ffout_empty,
		sw_ffout_we 	=> sw_ffout_we,
		sw_ffout_data 	=> sw_ffout_data
	);

	OUTFF: srl_fifo_32
    generic map(
		width 	=> DATA_WIDTH
	)
    port map(
        data_in      => sw_ffout_data,
        data_out     => FIFO_TO_SW,
        reset        => '0',
        write        => sw_ffout_we,
        read         => ffout_re,
        full         => sw_ffout_full,
        half_full    => open,
        data_present => sw_ffout_empty_n,
        clk          => clk
    );

	INFF: srl_fifo_32
    generic map(
				width 	=> DATA_WIDTH
	)
    port map(
        data_in      => FIFO_FROM_SW,
        data_out     => sw_ffin_data,
        reset        => '0',
        write        => ffin_we,
        read         => sw_ffin_re,
        full         => sw_ffin_full,
        half_full    => open,
        data_present => sw_ffin_empty_n,
        clk          => clk
    );

end Behavioral;

