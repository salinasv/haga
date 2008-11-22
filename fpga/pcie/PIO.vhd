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
---- Filename: PIO.vhd
----
---- Description: Programmed I/O module. Design implements 8 KBytes of programmable
----              memory space. Host processor can access this memory space using
----              Memory Read 32 and Memory Write 32 TLPs. Design accepts 
----              1 Double Word (DW) payload length on Memory Write 32 TLP and
----              responds to 1 DW length Memory Read 32 TLPs with a Completion
----              with Data TLP (1DW payload).
----              
----              Module is designed to operate with 32 bit and 64 bit interfaces.
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity PIO is

port (
  reg_out                : out std_logic_vector(7 downto 0);
	
  trn_clk                : in std_logic;         
  trn_reset_n            : in std_logic;
  trn_lnk_up_n           : in std_logic;

  trn_td                 : out std_logic_vector((64 - 1) downto 0);
  trn_trem_n             : out std_logic_vector(7 downto 0);
  trn_tsof_n             : out std_logic;
  trn_teof_n             : out std_logic;
  trn_tsrc_rdy_n         : out std_logic;
  trn_tsrc_dsc_n         : out std_logic;
  trn_tdst_rdy_n         : in std_logic;
  trn_tdst_dsc_n         : in std_logic;

  trn_rd                 : in std_logic_vector((64 - 1) downto 0);
  trn_rrem_n             : in std_logic_vector(7 downto 0);
  trn_rsof_n             : in std_logic;
  trn_reof_n             : in std_logic;
  trn_rsrc_rdy_n         : in std_logic;
  trn_rsrc_dsc_n         : in std_logic;
  trn_rbar_hit_n         : in std_logic_vector(6 downto 0);
  trn_rdst_rdy_n         : out std_logic;
  cfg_to_turnoff_n       : in std_logic;
  cfg_turnoff_ok_n       : out std_logic;

  cfg_completer_id       : in std_logic_vector(15 downto 0);
  cfg_bus_mstr_enable    : in std_logic

);    

end PIO;

architecture rtl of PIO is	 

-- Local wires

signal req_compl      : std_logic;
signal compl_done     : std_logic;
signal pio_reset_n    : std_logic;

component PIO_EP

port (
  reg_out                : out std_logic_vector(7 downto 0);

  clk                    : in std_logic;
  rst_n                  : in std_logic;

  -- LocalLink Tx

  trn_td                 : out std_logic_vector((64 - 1) downto 0);
  trn_trem_n             : out std_logic_vector(7 downto 0);

  trn_tsof_n             : out std_logic;
  trn_teof_n             : out std_logic;
  trn_tsrc_dsc_n         : out std_logic;
  trn_tsrc_rdy_n         : out std_logic;
  trn_tdst_dsc_n         : in std_logic;
  trn_tdst_rdy_n         : in std_logic;

  -- LocalLink Rx

  trn_rd                 : in std_logic_vector((64 - 1) downto 0);
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
end component;


component PIO_TO_CTRL
port (

  clk : in std_logic;
  rst_n : in std_logic;

  req_compl_i : in std_logic;
  compl_done_i : in std_logic;

  cfg_to_turnoff_n : in std_logic;
  cfg_turnoff_ok_n : out std_logic
);
end component;



begin

pio_reset_n  <= trn_reset_n and (not trn_lnk_up_n);

-- PIO instance

PIO_EP_ins : PIO_EP

port map (
  reg_out => reg_out,                        -- O (7:0)

  clk => trn_clk,                            -- I
  rst_n => pio_reset_n,                      -- I

  trn_td => trn_td,                          -- O [63/31:0]
  trn_trem_n => trn_trem_n,                  -- O
  trn_tsof_n => trn_tsof_n,                  -- O
  trn_teof_n => trn_teof_n,                  -- O
  trn_tsrc_rdy_n => trn_tsrc_rdy_n,          -- O
  trn_tsrc_dsc_n => trn_tsrc_dsc_n,          -- O
  trn_tdst_rdy_n => trn_tdst_rdy_n,          -- I
  trn_tdst_dsc_n => trn_tdst_dsc_n,          -- I

  trn_rd => trn_rd,                          -- I [63/31:0]

  trn_rrem_n => trn_rrem_n,                  -- I
  trn_rsof_n => trn_rsof_n,                  -- I
  trn_reof_n => trn_reof_n,                  -- I
  trn_rsrc_rdy_n => trn_rsrc_rdy_n,          -- I
  trn_rsrc_dsc_n => trn_rsrc_dsc_n,          -- I
  trn_rbar_hit_n => trn_rbar_hit_n,     -- I
  trn_rdst_rdy_n => trn_rdst_rdy_n,          -- O

  req_compl_o => req_compl,                  -- O
  compl_done_o => compl_done,                -- O

  cfg_completer_id => cfg_completer_id,      -- I [15:0]
  cfg_bus_mstr_enable => cfg_bus_mstr_enable -- I

);


    --
    -- Turn-Off controller
    --

PIO_TO : PIO_TO_CTRL port map   (

   clk => trn_clk,                             -- I
   rst_n => trn_reset_n,                       -- I

   req_compl_i => req_compl,                   -- I
   compl_done_i => compl_done,                 -- I

   cfg_to_turnoff_n => cfg_to_turnoff_n,       -- I
   cfg_turnoff_ok_n => cfg_turnoff_ok_n        -- O

);

end;  -- PIO
