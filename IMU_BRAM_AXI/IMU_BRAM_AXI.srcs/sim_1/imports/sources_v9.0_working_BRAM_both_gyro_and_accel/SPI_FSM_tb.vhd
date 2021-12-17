----------------------------------------------------------------------------------
-- Company: SDU
-- Engineer: Arkadiusz Nowakowski
-- 
-- Create Date: 11/03/2021 07:14:42 PM
-- Design Name: SPI comunication
-- Module Name: SPI_FSM_tb - Behavioral
-- Project Name: IMU interface
-- Target Devices: Sparkfun ICM-20948
-- Tool Versions: 
-- Description: testbench for SPI interface
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
--use IEEE.STD_LOGIC_ARITH.all;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_FSM_tb is
    --  Port ( );
end SPI_FSM_tb;

architecture Behavioral of SPI_FSM_tb is

    constant T : time := 8ns; --125MHz clock period
    signal IMU_data : std_logic_vector (7 downto 0);

    signal clk : STD_LOGIC;
    signal rst :  STD_LOGIC;
    signal en :  STD_LOGIC;
    signal addr :  STD_LOGIC_VECTOR (7 downto 0);
    signal din :  std_logic_vector (7 downto 0);
    signal wr :  std_logic;
    signal MISO :  STD_LOGIC;
    signal SCLK :  STD_LOGIC;
    signal MOSI :  STD_LOGIC;
    signal cs :  STD_LOGIC;
    signal dout :  STD_LOGIC_VECTOR (7 downto 0);

begin

    design_top_unit : entity work.SPI_FSM
        port map (clk=>clk, rst=>rst, en=>en, addr=>addr, din=>din, wr=>wr,
                 MISO=>MISO, SCLK=>SCLK, MOSI=>MOSI, cs=>cs, dout=>dout);
    clock : process
    begin
        clk<='0';
        wait for T;
        clk<='1';
        wait for T;
    end process clock;

    rst <='1', '0' after T;

    simulation :process
    begin
        en <= '0';

        wait for 2*T;

        addr(7) <= '0'; -- to set write mode in IMU
        addr(6 downto 0) <= "0000110"; -- IMU register addres hex 06
        din <= (others=>'0');
        wr <= '1';
        en<='1';

        wait for 4*T;

        while (cs = '0') loop
            wait for 0.5*T;
        end loop;

        en <= '0';

        wait for 20*T;

        addr(7) <= '1'; -- to set read mode in IMU
        addr(6 downto 0) <= "0000000"; -- IMU register addres hex 00
        din <= (others=>'0');
        wr <= '0';
        en<='1';

        IMU_data <= "11101010"; --hex EA
        wait for 45*T;

        while (SCLK = '1') loop
            wait for 0.5*T;
        end loop;

        for index in 7 downto 0 loop
            MISO <= IMU_data(index);
            wait for 4*T;
        end loop;

        wait for 4*T;

        while (cs = '0') loop
            wait for T;
        end loop;
        en <= '0';

    end process simulation;

end Behavioral;
