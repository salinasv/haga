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
---- Filename: PIO_64_RX_ENGINE.vhd
----
---- Description: 32 bit Local-Link Receive Unit.
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity PIO_64_RX_ENGINE is
	generic (
	BAR_ADDR_WIDTH 	: integer := 11;
	BAR_EN_WIDTH 	: integer := 2
);
	port (

  clk               : in std_logic;
  rst_n             : in std_logic;

--
-- Receive local link interface from PCIe core
--
   
  trn_rd            : in std_logic_vector(63 downto 0);
  trn_rrem_n        : in std_logic_vector(7 downto 0);
  trn_rsof_n        : in std_logic;
  trn_reof_n        : in std_logic;
  trn_rsrc_rdy_n    : in std_logic;
  trn_rsrc_dsc_n    : in std_logic;
  trn_rbar_hit_n    : in std_logic_vector(6 downto 0);
  trn_rdst_rdy_n    : out std_logic;

  req_compl_o       : out std_logic;
  req_compl_with_data_o  : out std_logic; -- asserted indicates to generate a completion WITH data
                                                             -- otherwise a completion WITHOUT data will be generated
  compl_done_i      : in std_logic;

--
-- Memory Read data handshake with Completion
-- transmit unit. Transmit unit reponds to
-- req_compl assertion and responds with compl_done
-- assertion when a Completion w/ data is transmitted.
--

  req_tc_o          : out std_logic_vector(2 downto 0); -- Memory Read TC
  req_td_o          : out std_logic; -- Memory Read TD
  req_ep_o          : out std_logic; -- Memory Read EP
  req_attr_o        : out std_logic_vector(1 downto 0); -- Memory Read Attribute
  req_len_o         : out std_logic_vector(9 downto 0); -- Memory Read Length (1DW)
  req_rid_o         : out std_logic_vector(15 downto 0); -- Memory Read Requestor ID
  req_tag_o         : out std_logic_vector(7 downto 0); -- Memory Read Tag
  req_be_o          : out std_logic_vector(7 downto 0); -- Memory Read Byte Enables
  req_addr_o        : out std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0); -- Memory Read Address

-- 
-- Memory interface used to save 1 DW data received
-- on Memory Write 32 TLP. Data extracted from
-- inbound TLP is presented to the Endpoint memory
-- unit. Endpoint memory unit reacts to wr_en_o
-- assertion and asserts wr_busy_i when it is
-- processing written information.
--

  -- Memory Write Address
  wr_addr_o         : out std_logic_vector((BAR_ADDR_WIDTH+BAR_EN_WIDTH)-1 downto 0);
  wr_be_o           : out std_logic_vector(7 downto 0); -- Memory Write Byte Enable
  wr_data_o         : out std_logic_vector(31 downto 0); -- Memory Write Data
  wr_en_o           : out std_logic; -- Memory Write Enable
  wr_busy_i         : in std_logic -- Memory Write Busy
);
	 
end PIO_64_RX_ENGINE;

architecture rtl of PIO_64_RX_ENGINE is
	 
constant RX_MEM_RD32_FMT_TYPE    : std_logic_vector(6 downto 0) := "0000000"; 
constant RX_MEM_WR32_FMT_TYPE    : std_logic_vector(6 downto 0) := "1000000"; 
constant RX_MEM_RD64_FMT_TYPE    : std_logic_vector(6 downto 0) := "0100000"; 
constant RX_MEM_WR64_FMT_TYPE    : std_logic_vector(6 downto 0) := "1100000";
constant RX_IO_RD32_FMT_TYPE     : std_logic_vector(6 downto 0) := "0000010"; 
constant RX_IO_WR32_FMT_TYPE     : std_logic_vector(6 downto 0) := "1000010"; 

type state_type is (RX_RST_STATE,
                    RX_MEM_RD32_DW1DW2,
                    RX_MEM_WR32_DW1DW2,
                    RX_IO_WR_DW1DW2,
                    RX_MEM_RD64_DW1DW2,
                    RX_MEM_WR64_DW1DW2,
                    RX_MEM_WR64_DW3,
                    RX_WAIT_STATE);

signal state              : state_type;
signal tlp_type           : std_logic_vector(6 downto 0);
signal trn_rdst_rdy_n_int : std_logic;
--signal io_bar_hit_n       : std_logic;
--signal mem32_bar_hit_n    : std_logic;
--signal mem64_bar_hit_n    : std_logic;
--signal erom_bar_hit_n     : std_logic;
--signal bar_hit_select     : std_logic_vector(3 downto 0);
signal region_select      : std_logic_vector(1 downto 0);

begin

trn_rdst_rdy_n <= trn_rdst_rdy_n_int; 

--mem64_bar_hit_n <= '1';
--io_bar_hit_n <= '1';
--mem32_bar_hit_n <= trn_rbar_hit_n(0);
--erom_bar_hit_n  <= trn_rbar_hit_n(6);


process (clk, rst_n)
begin
  if (rst_n = '0' ) then
    trn_rdst_rdy_n_int <= '0';
    req_compl_o    <= '0';
    req_compl_with_data_o  <= '1';
    req_tc_o       <= (others => '0');
    req_td_o       <= '0';
    req_ep_o       <= '0';
    req_attr_o     <= (others => '0');
    req_len_o      <= (others => '0');
    req_rid_o      <= (others => '0');
    req_tag_o      <= (others => '0');
    req_be_o       <= (others => '0');
    req_addr_o     <= (others => '0');
    wr_be_o        <= (others => '0');
    wr_addr_o      <= (others => '0');
    wr_data_o      <= (others => '0');
    wr_en_o        <= '0';
    state          <= RX_RST_STATE;
    tlp_type       <= (others => '0');
  else
    if (clk'event and clk = '1') then
     
      wr_en_o        <= '0';
      req_compl_o    <= '0';
      req_compl_with_data_o  <= '1';

      case (state) is

        -- Wait in reset state until Memory or IO TLP with 1 DW payload is received
        when RX_RST_STATE =>
          
          trn_rdst_rdy_n_int <= '0';

          -- if start of rx trn transaction
          if ((trn_rsof_n = '0') and (trn_rsrc_rdy_n = '0')
             and (trn_rdst_rdy_n_int = '0')) then

            -- check tlp fmt and type fields
            case (trn_rd(62 downto 56)) is

              -- tlp is mem32 read request
              when RX_MEM_RD32_FMT_TYPE =>
       
                tlp_type           <= trn_rd(62 downto 56);
                req_len_o          <= trn_rd(41 downto 32);
                trn_rdst_rdy_n_int <= '1';

                -- if tlp payload length is 1 DW, then process
                if (trn_rd(41 downto 32) = "0000000001") then

                  req_tc_o     <= trn_rd(54 downto 52);
                  req_td_o     <= trn_rd(47);
                  req_ep_o     <= trn_rd(46);
                  req_attr_o   <= trn_rd(45 downto 44);
                  req_len_o    <= trn_rd(41 downto 32);
                  req_rid_o     <= trn_rd(31 downto 16);
                  req_tag_o    <= trn_rd(15 downto 8);
                  req_be_o     <= trn_rd(7 downto 0);
                  state        <= RX_MEM_RD32_DW1DW2;

                else

                  state        <= RX_RST_STATE;

                end if;

              -- tlp is mem32 write request 
              when RX_MEM_WR32_FMT_TYPE =>

                tlp_type     <= trn_rd(62 downto 56);
                req_len_o    <= trn_rd(41 downto 32);
                trn_rdst_rdy_n_int <= '1';

                -- if tlp payload length is 1 DW, then process
                if (trn_rd(41 downto 32) = "0000000001") then

                  wr_be_o      <= trn_rd(7 downto 0);
                  state        <= RX_MEM_WR32_DW1DW2;
  
                else

                  state        <= RX_RST_STATE;

                end if;

              -- tlp is mem64 read request
              when RX_MEM_RD64_FMT_TYPE =>

                tlp_type     <= trn_rd(62 downto 56);
                req_len_o    <= trn_rd(41 downto 32);
                trn_rdst_rdy_n_int <= '1';

                -- if tlp payload length is 1 DW, then process
                if (trn_rd(41 downto 32) = "0000000001") then

                  req_tc_o     <= trn_rd(54 downto 52);
                  req_td_o     <= trn_rd(47);
                  req_ep_o     <= trn_rd(46);
                  req_attr_o   <= trn_rd(45 downto 44);
                  req_len_o    <= trn_rd(41 downto 32);
                  req_rid_o    <= trn_rd(31 downto 16);
                  req_tag_o    <= trn_rd(15 downto 08);
                  req_be_o     <= trn_rd(07 downto 00);
                  state        <= RX_MEM_RD64_DW1DW2;
          
                else

                  state        <= RX_RST_STATE;

                end if;

              -- tlp is mem64 write request
              when RX_MEM_WR64_FMT_TYPE =>

                tlp_type     <= trn_rd(62 downto 56);
                req_len_o    <= trn_rd(41 downto 32);

                -- if tlp payload length is 1 DW, then process
                if (trn_rd(41 downto 32) = "0000000001") then  

                  wr_be_o      <= trn_rd(7 downto 0);
                  state        <= RX_MEM_WR64_DW1DW2;

                else

                  state        <= RX_RST_STATE;

                end if;

              -- tlp is io read request
              when RX_IO_RD32_FMT_TYPE =>

                tlp_type     <= trn_rd(62 downto 56);
                req_len_o    <= trn_rd(41 downto 32);
                trn_rdst_rdy_n_int <= '1'; 

                -- if tlp payload length is 1 DW then process
                if (trn_rd(41 downto 32) = "0000000001") then

                  req_tc_o     <= trn_rd(54 downto 52);
                  req_td_o     <= trn_rd(47);
                  req_ep_o     <= trn_rd(46);
                  req_attr_o   <= trn_rd(45 downto 44);
                  req_len_o    <= trn_rd(41 downto 32);
                  req_rid_o     <= trn_rd(31 downto 16);
                  req_tag_o    <= trn_rd(15 downto 8);
                  req_be_o     <= trn_rd(7 downto 0);
                  state        <= RX_MEM_RD32_DW1DW2;
               
                else

                  state        <= RX_RST_STATE;

                end if;

              -- tlp is io write request
              when RX_IO_WR32_FMT_TYPE =>

                tlp_type     <= trn_rd(62 downto 56);
                req_len_o    <= trn_rd(41 downto 32);
                trn_rdst_rdy_n_int <= '1'; 

                -- if tlp payload length is 1 DW then process 
                if (trn_rd(41 downto 32) = "0000000001") then

		  req_tc_o     <= trn_rd(54 downto 52);
                  req_td_o     <= trn_rd(47);
                  req_ep_o     <= trn_rd(46);
                  req_attr_o   <= trn_rd(45 downto 44);
                  req_len_o    <= trn_rd(41 downto 32);
                  req_rid_o     <= trn_rd(31 downto 16);
                  req_tag_o    <= trn_rd(15 downto 8);
                  req_be_o     <= trn_rd(7 downto 0);
                  wr_be_o      <= trn_rd(7 downto 0);
                  state        <= RX_IO_WR_DW1DW2; -- DRT

                else

                  state        <= RX_RST_STATE;

                end if;


              when others => -- other TLPs not supported

                state <= RX_RST_STATE;

            end case;

          else

            state <= RX_RST_STATE;

          end if;

        -- first and second dwords of mem32 read tlp
        when RX_MEM_RD32_DW1DW2 =>

          if (trn_rsrc_rdy_n = '0') then

            trn_rdst_rdy_n_int <= '1';
            req_addr_o   <= region_select(1 downto 0) & "00" &
                            trn_rd((34+BAR_ADDR_WIDTH-2)-1 downto 34);
            req_compl_o  <= '1';
            req_compl_with_data_o  <= '1';
            state        <= RX_WAIT_STATE;

          else

            state        <= RX_MEM_RD32_DW1DW2;

          end if;

        -- first and second dwords of mem32 write tlp
        when RX_MEM_WR32_DW1DW2 =>

          if (trn_rsrc_rdy_n = '0') then

            wr_data_o  <= trn_rd(31 downto 0);
            wr_en_o    <= '1';
            trn_rdst_rdy_n_int <= '1';
            wr_addr_o  <= region_select(1 downto 0) & "00" &
                          trn_rd((34+BAR_ADDR_WIDTH-2)-1 downto 34);
            state        <= RX_WAIT_STATE;

          else

            state        <= RX_MEM_WR32_DW1DW2;

          end if;

        -- first and second dwords of io write tlp
        when RX_IO_WR_DW1DW2 =>

          if (trn_rsrc_rdy_n = '0') then

            wr_data_o  <= trn_rd(31 downto 0);
            wr_en_o    <= '1';
            trn_rdst_rdy_n_int <= '1';
            wr_addr_o  <= region_select(1 downto 0) & "00" &
						  trn_rd(34+(BAR_ADDR_WIDTH-2)-1 downto 34);

            trn_rdst_rdy_n_int <= '1';           
            req_compl_o  <= '1';
            req_compl_with_data_o  <= '0';

	    state        <= RX_WAIT_STATE;

          else

            state        <= RX_IO_WR_DW1DW2;

          end if;

        -- first and second dwords of mem64 read tlp
        when RX_MEM_RD64_DW1DW2 =>

          if (trn_rsrc_rdy_n = '0') then

            req_addr_o   <= region_select(1 downto 0)  & "00" & trn_rd(10 downto 2);
            req_compl_o  <= '1';
            req_compl_with_data_o  <= '1';
            trn_rdst_rdy_n_int <= '1';
            state        <= RX_WAIT_STATE;

          else

            state        <= RX_MEM_RD64_DW1DW2;

          end if;
 
        -- first and second dwords of mem64 write tlp
        when RX_MEM_WR64_DW1DW2 =>

          if (trn_rsrc_rdy_n = '0') then

            trn_rdst_rdy_n_int <= '1';
            wr_addr_o  <= region_select(1 downto 0) &
						  trn_rd(10 downto 0);
            trn_rdst_rdy_n_int <= '1';
            -- tlp write data is not available until next clock
            state        <= RX_MEM_WR64_DW3;

          else

            state        <= RX_MEM_WR64_DW1DW2;

          end if;

        -- third dword of mem64 write tlp contains 1 DW write data
        when RX_MEM_WR64_DW3 =>

          if (trn_rsrc_rdy_n = '0') then

            wr_data_o  <= trn_rd(63 downto 32);
            wr_en_o    <= '1';
            trn_rdst_rdy_n_int <= '1';
            state        <= RX_WAIT_STATE;

          else

            state        <= RX_MEM_WR64_DW3;

          end if;

        -- Stay in wait state for
        --  1. Target writes until the write has been completed and
        --     written into BRAM.
        --  2. Target reads until the completion has been generated
        --     and has been successfully transmitted via the PIO's
        --     TX interface.
	-- 3. IO Write and Extended CFG write until the completion 
	--     has been generated and has been successfully transmitted
	--     via the PIOs TX interface

        when RX_WAIT_STATE =>
    
          wr_en_o      <= '0';
          req_compl_o  <= '0';
          if ((tlp_type = RX_MEM_WR32_FMT_TYPE) and
             (wr_busy_i = '0')) then

            trn_rdst_rdy_n_int <= '0';
            state        <= RX_RST_STATE;

          elsif ((tlp_type = RX_IO_WR32_FMT_TYPE) and
                (wr_busy_i = '0') and (compl_done_i = '1')) then -- DRT

            trn_rdst_rdy_n_int <= '0';
            state        <= RX_RST_STATE;

          elsif ((tlp_type = RX_MEM_WR64_FMT_TYPE) and
                (wr_busy_i = '0')) then

            trn_rdst_rdy_n_int <= '0';
            state        <= RX_RST_STATE;

          elsif ((tlp_type = RX_MEM_RD32_FMT_TYPE) and
                (compl_done_i = '1')) then

            trn_rdst_rdy_n_int <= '0';
            state        <= RX_RST_STATE;

          elsif ((tlp_type = RX_IO_RD32_FMT_TYPE) and
                (compl_done_i = '1')) then

            trn_rdst_rdy_n_int <= '0';
            state        <= RX_RST_STATE;

          elsif ((tlp_type = RX_MEM_RD64_FMT_TYPE) and
                (compl_done_i = '1')) then

            trn_rdst_rdy_n_int <= '0';
            state        <= RX_RST_STATE;

          else

            state        <= RX_WAIT_STATE;

          end if;

        when others =>

          state <= RX_WAIT_STATE;

      end  case;

    end if;

  end if;

end process;

-- bar_hit_select is used to map the four dedicated bar hit signals to the
-- correct BlockRAM address. This ensures that TLPs destined to BARs that
-- are configured for IO, Mem32, Mem64, and EROM transactions will be
-- written to the PIO's BlockRAM memories that have been dedicated for IO, 
-- Mem32, Mem64,and Erom TLP storage, respectively.

--bar_hit_select <= io_bar_hit_n & mem32_bar_hit_n & mem64_bar_hit_n & erom_bar_hit_n;


--process (bar_hit_select)
process (trn_rbar_hit_n)
begin

  case (trn_rbar_hit_n) is
				
    when "1111110" =>

      -- Enable BlockRAM reserved for IO TLPs for read or write
      region_select <= "00";

    when "1111101" =>

      -- Enable BlockRAM reserved for Mem32 TLPs for read or write
      region_select <= "01";

    when "1111011" =>

      -- Enable BlockRAM reserved for Mem64 TLPs for read or write
      region_select <= "10";

    when "1110111" =>

      -- Enable BlockRAM reserved for Mem32 EROM TLPs for read or write
      region_select <= "11";

    when others =>

      region_select <= "00";

  end  case;

end process;


end; -- PIO_64_RX_ENGINE

