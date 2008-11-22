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
-- Filename: PIO_TO_CTRL.vhd
--
-- Description: Turn-off Control Unit 
--               
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity PIO_TO_CTRL  is port (

  clk                 : in std_logic;
  rst_n               : in std_logic;
	 
  req_compl_i         : in std_logic;
  compl_done_i        : in std_logic;
	
  cfg_to_turnoff_n    : in std_logic;
  cfg_turnoff_ok_n    : out std_logic
	 
 
);
	 
end PIO_TO_CTRL;	 



architecture RTL of PIO_TO_CTRL is

signal trn_pending : std_logic;

begin
     
-- Check if completion is pending
	  
process (clk, rst_n) 

begin

  if (rst_n = '1') then

    trn_pending <= '0';

  else

    if (clk'event and clk = '1') then

      if ((trn_pending = '0') and (req_compl_i = '1')) then

        trn_pending <= '1';

      elsif (compl_done_i =  '1') then

        trn_pending <= '0';

      end if;

    end if;

  end if;

end process;

   
--  Turn-off OK if requested and no transaction is pending

process (cfg_to_turnoff_n, trn_pending)

begin

  if ((cfg_to_turnoff_n = '0') and (trn_pending = '0')) then

    cfg_turnoff_ok_n <= '0';

  else 

    cfg_turnoff_ok_n <= '1';

  end if;

end process;		

end; -- PIO_TO_CTRL

