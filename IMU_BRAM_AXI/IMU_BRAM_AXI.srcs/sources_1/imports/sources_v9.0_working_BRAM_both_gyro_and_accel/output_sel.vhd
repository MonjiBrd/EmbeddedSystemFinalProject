----------------------------------------------------------------------------------
-- Company: SDU
-- Engineer: Arkadiusz Nowakowski
-- 
-- Create Date: 11/14/2021 02:49:07 PM
-- Design Name: IMU_BRAM_AXI
-- Module Name: output_sel - rtl
-- Project Name: IMU interface
-- Target Devices: Sparkfun ICM-20948
-- Tool Versions: 
-- Description: Visualisation and debug purposes - to select 3 bit part of BRAM data output and 
--              put it on RGB LED (it's 7 downto 5 from IMU data)
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity output_sel is
    Port ( din : in STD_LOGIC_VECTOR (31 downto 0);
           dout : out STD_LOGIC_VECTOR (2 downto 0));
end output_sel;

architecture rtl of output_sel is

begin

dout<=din (7 downto 5);

end rtl;
