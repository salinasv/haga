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
---- Filename: PIO_64_TX_ENGINE.vhd
----
---- Description: 64 bit Local-Link Transmit Unit.
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity PIO_64_TX_ENGINE is 
	generic (
	BAR_ADDR_WIDTH 	: integer := 11;
	BAR_EN_WIDTH 	: integer := 2
);
	port (

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
  req_compl_with_data_i  : in std_logic; -- asserted indicates to generate a completion WITH data
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
  req_addr_i               : in std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0);

  rd_addr_o                : out std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0);
  rd_be_o                  : out std_logic_vector( 3 downto 0);
  rd_data_i                : in std_logic_vector(31 downto 0);

  completer_id_i           : in std_logic_vector(15 downto 0);
  cfg_bus_mstr_enable_i    : in std_logic

);

end PIO_64_TX_ENGINE;

architecture rtl of PIO_64_TX_ENGINE is

constant TX_CPLD_FMT_TYPE    : std_logic_vector(6 downto 0) := "1001010";
constant TX_CPL_FMT_TYPE      : std_logic_vector(6 downto 0) := "0001010";

type state_type is (TX_RST_STATE, TX_CPLD_QW1, TX_CPL_QW1);

signal state              : state_type;
signal byte_count     : std_logic_vector(11 downto 0);
signal lower_addr     : std_logic_vector(6 downto 0);
signal rd_be_o_int    : std_logic_vector(3 downto 0);
signal req_compl_q    : std_logic;
signal req_compl_with_data_q : std_logic;

-- Local wires

begin

  trn_tsrc_dsc_n   <= '1';
  rd_be_o <= rd_be_o_int;

  -- Present address and byte enable to memory module

  rd_addr_o <= req_addr_i;
  rd_be_o_int  <=  req_be_i(3 downto 0);

-- Calculate byte count based on byte enable

process(rd_be_o_int)
begin

  case  rd_be_o_int(3 downto 0) is

    when X"9" => byte_count <= X"004";
    when X"B" => byte_count <= X"004";
    when X"D" => byte_count <= X"004";
    when X"F" => byte_count <= X"004";
    when X"5" => byte_count <= X"003";
    when X"7" => byte_count <= X"003";
    when X"A" => byte_count <= X"003";
    when X"E" => byte_count <= X"003";
    when X"3" => byte_count <= X"002";
    when X"6" => byte_count <= X"002";
    when X"C" => byte_count <= X"002";
    when X"1" => byte_count <= X"001";
    when X"2" => byte_count <= X"001";
    when X"4" => byte_count <= X"001";
    when X"8" => byte_count <= X"001";
    when X"0" => byte_count <= X"001";
    when others => byte_count <= X"001";

  end case;

end process;

-- Calculate lower address based on  byte enable

process(rd_be_o_int, req_addr_i)
begin

   if (rd_be_o_int(0) = '1') then


      -- when "---1"
      lower_addr <= req_addr_i(6 downto 2) & "00";

   elsif (rd_be_o_int(1) = '1') then

      -- when "--10"
      lower_addr <= req_addr_i(6 downto 2) & "01";

   elsif (rd_be_o_int(2) = '1') then

      -- when "-100"
      lower_addr <= req_addr_i(6 downto 2) & "10";

   elsif (rd_be_o_int(3) = '1') then

      -- when "1000"
      lower_addr <= req_addr_i(6 downto 2) & "11";

   else

      -- when "0000"
      lower_addr <= req_addr_i(6 downto 2) & "00";

   end if;


end process;


process (rst_n, clk)
begin
  
  if (rst_n = '0') then
    
    req_compl_q <= '0';
    req_compl_with_data_q <= '1';

  else

    if (clk'event and clk = '1') then

      req_compl_q <= req_compl_i;
      req_compl_with_data_q <= req_compl_with_data_i;

    end if;

  end if;

end process;


--  State Machine to generate Completion with 1 DW Payload or Completion without Data

process (rst_n, clk)
begin

  if (rst_n = '0' ) then

    trn_tsof_n        <= '1';
    trn_teof_n        <= '1';
    trn_tsrc_rdy_n    <= '1';
    trn_td            <= (others => '0'); -- 64-bits
    trn_trem_n    <= (others => '0'); -- 8-bits
    compl_done_o      <= '0';
    state             <= TX_RST_STATE;

  else

    if (clk'event and clk = '1') then

      compl_done_o      <= '0';

      case ( state ) is

        when TX_RST_STATE =>

          if ((trn_tdst_rdy_n = '0') and (req_compl_q = '1') and
             (req_compl_with_data_q = '1') and (trn_tdst_dsc_n = '1')) then

            trn_tsof_n       <= '0';
            trn_teof_n       <= '1';
            trn_tsrc_rdy_n   <= '0';
            trn_td           <= '0' &
                                TX_CPLD_FMT_TYPE &
                                '0' &
                                req_tc_i &
                                "0000" &
                                req_td_i &
                                req_ep_i &
                                req_attr_i &
                                "00" &
                                req_len_i &
                                completer_id_i &
                                "000" &
                                '0' &
                                byte_count;
            trn_trem_n       <= (others => '0'); -- 8-bit
            state            <= TX_CPLD_QW1;

          elsif  ((trn_tdst_rdy_n = '0') and (req_compl_q = '1') and
             (req_compl_with_data_q = '0') and (trn_tdst_dsc_n = '1')) then

            trn_tsof_n       <= '0';
            trn_teof_n       <= '1';
            trn_tsrc_rdy_n   <= '0';
            trn_td           <= '0' &
                                TX_CPL_FMT_TYPE &
                                '0' &
                                req_tc_i &
                                "0000" &
                                req_td_i &
                                req_ep_i &
                                req_attr_i &
                                "00" &
                                req_len_i &
                                completer_id_i &
                                "000" &
                                '0' &
                                byte_count;
            trn_trem_n       <= (others => '0'); -- 8-bit
            state            <= TX_CPL_QW1;

         else

            trn_tsof_n       <= '1';
            trn_teof_n       <= '1';
            trn_tsrc_rdy_n   <= '1';
            trn_td           <= (others => '0'); -- 64-bit
            trn_trem_n       <= (others => '0'); -- 8-bit
            compl_done_o     <= '0';
            state            <= TX_RST_STATE;

          end if;


        when TX_CPLD_QW1 =>

          if ((trn_tdst_rdy_n = '0') and (trn_tdst_dsc_n = '1')) then

            trn_tsof_n       <= '1';
            trn_teof_n       <= '0';
            trn_tsrc_rdy_n   <= '0';
            trn_td           <= req_rid_i &
                                req_tag_i &
                                '0' &
                                lower_addr &
                                rd_data_i;
            trn_trem_n       <= "00000000";
            compl_done_o     <= '1';
            state            <= TX_RST_STATE;

          elsif (trn_tdst_dsc_n = '0') then

            state            <= TX_RST_STATE;


          else

            state           <= TX_CPLD_QW1;

          end if;

         when TX_CPL_QW1 =>

          if ((trn_tdst_rdy_n = '0') and (trn_tdst_dsc_n = '1')) then

            trn_tsof_n       <= '1';
            trn_teof_n       <= '0';
            trn_tsrc_rdy_n   <= '0';
            trn_td           <= req_rid_i &
                                req_tag_i &
                                '0' &
                                lower_addr &
                                X"00000000";
            trn_trem_n       <= "00001111";
            compl_done_o     <= '1';
            state            <= TX_RST_STATE;

          elsif (trn_tdst_dsc_n = '0') then

            state            <= TX_RST_STATE;


          else

            state           <= TX_CPL_QW1;

          end if;

        when others => NULL;

      end case;

    end if;

  end if;

end process;

end; -- PIO_64_TX_ENGINE

