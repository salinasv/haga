-- DISCLAIMER OF LIABILITY
--
-- This text/file contains proprietary, confidential
-- information of Xilinx, Inc., is distributed under license
-- from Xilinx, Inc., and may be used, copied and/or
-- disclosed only pursuant to the terms of a valid license
-- agreement with Xilinx, Inc. Xilinx hereby grants you
-- a license to use this text/file solely for design, simulation,
-- implementation and creation of design files limited
-- to Xilinx devices or technologies. Use with non-Xilinx
-- devices or technologies is expressly prohibited and
-- immediately terminates your license unless covered by
-- a separate agreement.
--
-- Xilinx is providing this design, code, or information
-- "as is" solely for use in developing programs and
-- solutions for Xilinx devices. By providing this design,
-- code, or information as one possible implementation of
-- this feature, application or standard, Xilinx is making no
-- representation that this implementation is free from any
-- claims of infringement. You are responsible for
-- obtaining any rights you may require for your implementation.
-- Xilinx expressly disclaims any warranty whatsoever with
-- respect to the adequacy of the implementation, including
-- but not limited to any warranties or representations that this
-- implementation is free from claims of infringement, implied
-- warranties of merchantability or fitness for a particular
-- purpose.
--
-- Xilinx products are not intended for use in life support
-- appliances, devices, or systems. Use in such applications are
-- expressly prohibited.
--
--
-- Copyright (c) 2001, 2002, 2003, 2004, 2005, 2007 Xilinx, Inc. All rights reserved.
--
-- This copyright and support notice must be retained as part
-- of this text at all times.
--
---- Filename: PIO_EP.vhd
----
---- Description: Endpoint Programmed I/O module. 
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity PIO_EP is
port (
  reg_out                : out std_logic_vector(7 downto 0);

  clk                    : in std_logic;
  rst_n                  : in std_logic;

  -- LocalLink Tx
    
  trn_td                 : out std_logic_vector(( 64 - 1) downto 0);
  trn_trem_n             : out std_logic_vector(7 downto 0);

  trn_tsof_n             : out std_logic;
  trn_teof_n             : out std_logic;
  trn_tsrc_dsc_n         : out std_logic;
  trn_tsrc_rdy_n         : out std_logic;
  trn_tdst_dsc_n         : in std_logic;
  trn_tdst_rdy_n         : in std_logic;
    
  -- LocalLink Rx

  trn_rd                 : in std_logic_vector(( 64 - 1) downto 0);
  trn_rrem_n             : in std_logic_vector(7 downto 0);
  trn_rsof_n             : in std_logic;
  trn_reof_n             : in std_logic;
  trn_rsrc_rdy_n         : in std_logic;
  trn_rsrc_dsc_n         : in std_logic;
  trn_rbar_hit_n         : in std_logic_vector(6 downto 0);
  trn_rdst_rdy_n         : out std_logic;
  
  req_compl_o            : out std_logic;
  compl_done_o           : out std_logic;

  cfg_completer_id       : in std_logic_vector(15 downto 0);
  cfg_bus_mstr_enable    : in std_logic

);
end PIO_EP;
    
architecture rtl of PIO_EP is
 
constant BAR_ADDR_WIDTH : integer := 11;
constant BAR_EN_WIDTH 	: integer := 2;

-- Local signals
    
  signal rd_addr       : std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0); 
  signal rd_be         : std_logic_vector(3 downto 0); 
  signal rd_data       : std_logic_vector(31 downto 0); 

  signal wr_addr       : std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0); 
  signal wr_be         : std_logic_vector(7 downto 0); 
  signal wr_data       : std_logic_vector(31 downto 0); 
  signal wr_en         : std_logic;
  signal wr_busy       : std_logic;

  signal req_compl     : std_logic;
  signal req_compl_with_data  : std_logic;
  signal compl_done    : std_logic;

  signal req_tc        : std_logic_vector(2 downto 0);
  signal req_td        : std_logic; 
  signal req_ep        : std_logic; 
  signal req_attr      : std_logic_vector(1 downto 0);
  signal req_len       : std_logic_vector(9 downto 0);
  signal req_rid       : std_logic_vector(15 downto 0);
  signal req_tag       : std_logic_vector(7 downto 0);
  signal req_be        : std_logic_vector(7 downto 0);
  signal req_addr      : std_logic_vector(12 downto 0);

component PIO_64_RX_ENGINE is
port (

  clk               : in std_logic;
  rst_n             : in std_logic;

  trn_rd            : in std_logic_vector(63 downto 0);
  trn_rrem_n        : in std_logic_vector(7 downto 0);
  trn_rsof_n        : in std_logic;
  trn_reof_n        : in std_logic;
  trn_rsrc_rdy_n    : in std_logic;
  trn_rsrc_dsc_n    : in std_logic;
  trn_rbar_hit_n    : in std_logic_vector(6 downto 0);
  trn_rdst_rdy_n    : out std_logic;

  req_compl_o       : out std_logic;
  req_compl_with_data_o  : out std_logic; -- asserted indicates to generate a completion WITH data    -- DRT
                                                             -- otherwise a completion WITHOUT data will be generated
  compl_done_i      : in std_logic;

  req_tc_o          : out std_logic_vector(2 downto 0); -- Memory Read TC
  req_td_o          : out std_logic; -- Memory Read TD
  req_ep_o          : out std_logic; -- Memory Read EP
  req_attr_o        : out std_logic_vector(1 downto 0); -- Memory Read Attribute
  req_len_o         : out std_logic_vector(9 downto 0); -- Memory Read Length (1DW)
  req_rid_o         : out std_logic_vector(15 downto 0); -- Memory Read Requestor ID
  req_tag_o         : out std_logic_vector(7 downto 0); -- Memory Read Tag
  req_be_o          : out std_logic_vector(7 downto 0); -- Memory Read Byte Enables
  req_addr_o        : out std_logic_vector(12 downto 0); -- Memory Read Address

  wr_addr_o         : out std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0); -- Memory Write Address
  wr_be_o           : out std_logic_vector(7 downto 0); -- Memory Write Byte Enable
  wr_data_o         : out std_logic_vector(31 downto 0); -- Memory Write Data
  wr_en_o           : out std_logic; -- Memory Write Enable
  wr_busy_i         : in std_logic -- Memory Write Busy

);
end component;

component PIO_64_TX_ENGINE is

port   (

  clk                      : in std_logic;
  rst_n                    : in std_logic;

  trn_td                   : out std_logic_vector( 63 downto 0);
  trn_trem_n               : out std_logic_vector(7 downto 0);
  trn_tsof_n               : out std_logic;
  trn_teof_n               : out std_logic;
  trn_tsrc_rdy_n           : out std_logic;
  trn_tsrc_dsc_n           : out std_logic;
  trn_tdst_rdy_n           : in std_logic;
  trn_tdst_dsc_n           : in std_logic;

  req_compl_i              : in std_logic;
  req_compl_with_data_i  : in std_logic; -- asserted indicates to generate a completion WITH data    -- DRT
                                                             -- otherwise a completion WITHOUT data will be generated
  compl_done_o             : out std_logic;

  req_tc_i                 : in std_logic_vector(2 downto 0);
  req_td_i                 : in std_logic;
  req_ep_i                 : in std_logic;
  req_attr_i               : in std_logic_vector(1 downto 0);
  req_len_i                : in std_logic_vector(9 downto 0);
  req_rid_i                : in std_logic_vector(15 downto 0);
  req_tag_i                : in std_logic_vector(7 downto 0);
  req_be_i                 : in std_logic_vector(7 downto 0);
  req_addr_i               : in std_logic_vector(12 downto 0);

  rd_addr_o                : out std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0);
  rd_be_o                  : out std_logic_vector( 3 downto 0);
  rd_data_i                : in std_logic_vector(31 downto 0);

  completer_id_i           : in std_logic_vector(15 downto 0);
  cfg_bus_mstr_enable_i    : in std_logic

);
end component;

--component PIO_EP_MEM_ACCESS is
--
--port (
--		
--  clk          : in std_logic;
--  rst_n        : in std_logic;
--
--  --  Read Port
--
--  rd_addr_i    : in std_logic_vector(10 downto 0);
--  rd_be_i      : in std_logic_vector(3 downto 0);
--  rd_data_o    : out std_logic_vector(31 downto 0);
--
--  --  Write Port
--
--  wr_addr_i    : in std_logic_vector(10 downto 0);
--  wr_be_i      : in std_logic_vector(7 downto 0);
--  wr_data_i    : in std_logic_vector(31 downto 0);
--  wr_en_i      : in std_logic;
--  wr_busy_o    : out std_logic
--
--);
--end component;

component registers is
	Port (
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
end component;

signal trn_td_int        : std_logic_vector(( 64 - 1) downto 0);
signal trn_trem_n_int    : std_logic_vector(7 downto 0);

--signal bar0_en 		: std_logic; 	-- Used to decode the BAR selector

begin

trn_trem_n    <= trn_trem_n_int;
trn_td        <= trn_td_int;

-- ENDPOINT MEMORY : 8KB memory aperture implemented in FPGA BlockRAM(*)  

--EP_MEM : PIO_EP_MEM_ACCESS port map (
EP_REG : registers port map (
  reg_out => reg_out,

  clk => clk,                           -- I
  rst_n => rst_n,                       -- I

  -- Read Port

  rd_addr_i => rd_addr,                 -- I [10:0]
  rd_be_i => rd_be,                     -- I [3:0]
  rd_data_o => rd_data,                 -- O [31:0]

  -- Write Port

  wr_addr_i => wr_addr,                 -- I [10:0]
  wr_be_i => wr_be,                     -- I [7:0]
  wr_data_i => wr_data,                 -- I [31:0]
  wr_en_i => wr_en,                     -- I
  wr_busy_o => wr_busy                  -- O

);

EP_RX_64 : PIO_64_RX_ENGINE port map (

  clk => clk,                           -- I
  rst_n => rst_n,                       -- I

  -- LocalLink Rx
  trn_rd => trn_rd,                     -- I [63/31:0]
  trn_rrem_n => trn_rrem_n,             -- I [7:0]
  trn_rsof_n => trn_rsof_n,             -- I
  trn_reof_n => trn_reof_n,             -- I
  trn_rsrc_rdy_n => trn_rsrc_rdy_n,     -- I
  trn_rsrc_dsc_n => trn_rsrc_dsc_n,     -- I
  trn_rbar_hit_n => trn_rbar_hit_n,     -- I [6:0]
  trn_rdst_rdy_n => trn_rdst_rdy_n,     -- O

  -- Handshake with Tx engine 

  req_compl_o => req_compl,             -- O
  req_compl_with_data_o => req_compl_with_data,  -- O
  compl_done_i => compl_done,           -- I

  req_tc_o => req_tc,                   -- O [2:0]
  req_td_o => req_td,                   -- O
  req_ep_o => req_ep,                   -- O
  req_attr_o => req_attr,               -- O [1:0]
  req_len_o => req_len,                 -- O [9:0]
  req_rid_o => req_rid,                 -- O [15:0]
  req_tag_o => req_tag,                 -- O [7:0]
  req_be_o => req_be,                   -- O [7:0]
  req_addr_o => req_addr,               -- O [12:0]

  -- Memory Write Port

  wr_addr_o => wr_addr,                 -- O [10:0]
  wr_be_o => wr_be,                     -- O [7:0]
  wr_data_o => wr_data,                 -- O [31:0]
  wr_en_o => wr_en,                     -- O
  wr_busy_i => wr_busy                  -- I
                   
);

-- Local-Link Transmit Controller

EP_TX_64 : PIO_64_TX_ENGINE  port map (

  clk => clk,                         -- I
  rst_n => rst_n,                     -- I

  -- LocalLink Tx
  trn_td => trn_td_int,               -- O [63/31:0]
  trn_trem_n => trn_trem_n_int,       -- O [7:0]
  trn_tsof_n => trn_tsof_n,           -- O
  trn_teof_n => trn_teof_n,           -- O
  trn_tsrc_dsc_n => trn_tsrc_dsc_n,   -- O
  trn_tsrc_rdy_n => trn_tsrc_rdy_n,   -- O
  trn_tdst_dsc_n => trn_tdst_dsc_n,   -- I
  trn_tdst_rdy_n => trn_tdst_rdy_n,   -- I

  -- Handshake with Rx engine 
  req_compl_i => req_compl,           -- I
  req_compl_with_data_i => req_compl_with_data, -- I
  compl_done_o => compl_done,         -- 0

  req_tc_i => req_tc,                 -- I [2:0]
  req_td_i => req_td,                 -- I
  req_ep_i => req_ep,                 -- I
  req_attr_i => req_attr,             -- I [1:0]
  req_len_i => req_len,               -- I [9:0]
  req_rid_i => req_rid,               -- I [15:0]
  req_tag_i => req_tag,               -- I [7:0]
  req_be_i => req_be,                 -- I [7:0]
  req_addr_i => req_addr,             -- I [12:0]
                    
  -- Read Port

  rd_addr_o => rd_addr,              -- O [10:0]
  rd_be_o => rd_be,                  -- O [3:0]
  rd_data_i => rd_data,              -- I [31:0]

  completer_id_i => cfg_completer_id,          -- I [15:0]
  cfg_bus_mstr_enable_i => cfg_bus_mstr_enable -- I

);

  req_compl_o     <= req_compl;
  compl_done_o    <= compl_done;

end; -- PIO_EP

