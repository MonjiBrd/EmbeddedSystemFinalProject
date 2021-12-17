----------------------------------------------------------------------------------
-- Company: SDU
-- Engineer: Arkadiusz Nowakowski
-- 
-- Create Date: 11/04/2021 05:23:43 PM
-- Design Name: SPI comunication
-- Module Name: IMU_interface_tb - Behavioral
-- Project Name: IMU interface
-- Target Devices: Sparkfun ICM-20948
-- Tool Versions: 
-- Description: testbench to mimic IMU behavior on SPI
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity IMU_interface_tb is
    --  Port ( );
end IMU_interface_tb;

architecture Behavioral of IMU_interface_tb is

    constant T : time := 8ns; --125MHz clock period
    constant Delay : time := 0.2*T; --unit response delay

    --external signals
    signal clk : STD_LOGIC;
    signal rst :  STD_LOGIC;
    signal en :  STD_LOGIC;
    signal MISO :  STD_LOGIC;
    signal SCLK :  STD_LOGIC;
    signal MOSI :  STD_LOGIC;
    signal cs :  STD_LOGIC;
    --signal dout :  STD_LOGIC_VECTOR (7 downto 0); --debug resuorce
    --signal tx : STD_LOGIC;
    signal LED_s : STD_LOGIC;
    signal LED_e : STD_LOGIC;
    signal BRAM_dout : STD_LOGIC_VECTOR (2 downto 0);
    
    --signals to port BRAM portA (unused in simulation):
    signal BRAM_PORTA_addr : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal BRAM_PORTA_clk : STD_LOGIC;
    signal BRAM_PORTA_din : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal BRAM_PORTA_dout : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal BRAM_PORTA_en : STD_LOGIC;
    signal BRAM_PORTA_rst : STD_LOGIC;
    signal BRAM_PORTA_we : STD_LOGIC_VECTOR ( 3 downto 0 );

    --internal registers
    signal addr_reg : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0'); --reg to load addr from MOSI
    signal din_reg : STD_LOGIC_VECTOR (7 downto 0) := (others=>'0'); --reg to load data from MOSI
    signal count : UNSIGNED (4 downto 0) := (others=>'0');
    signal reg_06 : STD_LOGIC_VECTOR (7 downto 0) := "11101010"; --register 0x00 with "who am I": EAh
    signal reg_error : STD_LOGIC_VECTOR (7 downto 0) := (others=>'1'); --wrong addres error indicator: FF'h
    signal addr_80 : unsigned (7 downto 0) := "10000000"; --results comparing base
    signal data_00 : unsigned (7 downto 0) := "00000000";
    
    --IMU register addr.
    signal gyro_ax_h_addr : unsigned (7 downto 0) := x"B3"; --addr to read from register 0x33
    signal gyro_ax_l_addr : unsigned (7 downto 0) := x"B4";
    signal gyro_ay_h_addr : unsigned (7 downto 0) := x"B5";
    signal gyro_ay_l_addr : unsigned (7 downto 0) := x"B6";
    signal gyro_az_h_addr : unsigned (7 downto 0) := x"B7";
    signal gyro_az_l_addr : unsigned (7 downto 0) := x"B8";
    
    signal accel_ax_h_addr : unsigned (7 downto 0) := x"AD"; --addr to read from register 0x2D
    signal accel_ax_l_addr : unsigned (7 downto 0) := x"AE";
    signal accel_ay_h_addr : unsigned (7 downto 0) := x"AF";
    signal accel_ay_l_addr : unsigned (7 downto 0) := x"B0";
    signal accel_az_h_addr : unsigned (7 downto 0) := x"B1";
    signal accel_az_l_addr : unsigned (7 downto 0) := x"B2";

--data is written the way we should see from BRAM_dout sequence of 1 2 3 4 5 6 7 0 1 2 3 4 
    --IMU register data (for simulation)
    signal reg_gyro_ax_h : STD_LOGIC_VECTOR (7 downto 0) := x"2F"; --testing register to simulate gyro incoming data
    signal reg_gyro_ax_l : STD_LOGIC_VECTOR (7 downto 0) := x"4B";
    signal reg_gyro_ay_h : STD_LOGIC_VECTOR (7 downto 0) := x"68";
    signal reg_gyro_ay_l : STD_LOGIC_VECTOR (7 downto 0) := x"82";
    signal reg_gyro_az_h : STD_LOGIC_VECTOR (7 downto 0) := x"A3";
    signal reg_gyro_az_l : STD_LOGIC_VECTOR (7 downto 0) := x"C9";
    
    signal reg_accel_ax_h : STD_LOGIC_VECTOR (7 downto 0) := x"EF"; --testing register to simulate accelerometer incoming data
    signal reg_accel_ax_l : STD_LOGIC_VECTOR (7 downto 0) := x"04";
    signal reg_accel_ay_h : STD_LOGIC_VECTOR (7 downto 0) := x"2D";
    signal reg_accel_ay_l : STD_LOGIC_VECTOR (7 downto 0) := x"47";
    signal reg_accel_az_h : STD_LOGIC_VECTOR (7 downto 0) := x"61";
    signal reg_accel_az_l : STD_LOGIC_VECTOR (7 downto 0) := x"82";
    
begin

    design_top_unit : entity work.IMU_interface_wrapper
        port map (clk=>clk, rst=>rst, en=>en, MISO=>MISO, SCLK=>SCLK, MOSI=>MOSI, cs=>cs,
        LED_s=>LED_s, LED_e=>LED_e, BRAM_dout=>BRAM_dout,
        --portA connections:
        BRAM_PORTA_addr=>BRAM_PORTA_addr, BRAM_PORTA_clk=>BRAM_PORTA_clk, BRAM_PORTA_din=>BRAM_PORTA_din,
        BRAM_PORTA_dout=>BRAM_PORTA_dout, BRAM_PORTA_en=>BRAM_PORTA_en, BRAM_PORTA_rst=>BRAM_PORTA_rst,
        BRAM_PORTA_we=>BRAM_PORTA_we);
    clock : process
    begin
        clk<='0';
        wait for T;
        clk<='1';
        wait for T;
    end process clock;

    rst <='1', '0' after 150*T;
    en <='0', '1' after 2*150*T;

    simulation :process(
SCLK,
 cs,
 count,
 addr_reg,
 din_reg
)
    begin
        --simulating IMU SPI behavior 
        if (cs = '0' and SCLK'event and SCLK='1') then
            if (count <= 7) then                            --addres part of SPI
                addr_reg <= addr_reg(6 downto 0) & MOSI;    --load sended addres
            elsif (count > 7 and addr_reg(7)='0') then      --data part of SPI in write data mode
                din_reg <= din_reg(6 downto 0) & MOSI;      --load sended data
            end if;
            count<=count+1;
        elsif (cs = '0' and SCLK'event and SCLK='0') then --MISO simulation - sending on falling SLC
            if (count > 7 and addr_reg(7)='1') then       --data part of SPI in read data mode
                if(unsigned(addr_reg)=addr_80) then
                    MISO <= reg_06(7);    --sending who am I signal from IMU simulator
                    reg_06<=reg_06(6 downto 0) & '0';
                    --report "read response right addres " severity note;
                elsif(unsigned(addr_reg)=gyro_ax_h_addr) then
                    MISO <= reg_gyro_ax_h(7);    --sending gyro data
                    reg_gyro_ax_h<=reg_gyro_ax_h(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=gyro_ax_l_addr) then
                    MISO <= reg_gyro_ax_l(7);    --sending gyro data
                    reg_gyro_ax_l<=reg_gyro_ax_l(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=gyro_ay_h_addr) then
                    MISO <= reg_gyro_ay_h(7);    --sending gyro data
                    reg_gyro_ay_h<=reg_gyro_ay_h(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=gyro_ay_l_addr) then
                    MISO <= reg_gyro_ay_l(7);    --sending gyro data
                    reg_gyro_ay_l<=reg_gyro_ay_l(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=gyro_az_h_addr) then
                    MISO <= reg_gyro_az_h(7);    --sending gyro data
                    reg_gyro_az_h<=reg_gyro_az_h(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=gyro_az_l_addr) then
                    MISO <= reg_gyro_az_l(7);    --sending gyro data
                    reg_gyro_az_l<=reg_gyro_az_l(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=accel_ax_h_addr) then
                    MISO <= reg_accel_ax_h(7);    --sending gyro data
                    reg_accel_ax_h<=reg_accel_ax_h(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=accel_ax_l_addr) then
                    MISO <= reg_accel_ax_l(7);    --sending gyro data
                    reg_accel_ax_l<=reg_accel_ax_l(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=accel_ay_h_addr) then
                    MISO <= reg_accel_ay_h(7);    --sending gyro data
                    reg_accel_ay_h<=reg_accel_ay_h(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=accel_ay_l_addr) then
                    MISO <= reg_accel_ay_l(7);    --sending gyro data
                    reg_accel_ay_l<=reg_accel_ay_l(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=accel_az_h_addr) then
                    MISO <= reg_accel_az_h(7);    --sending gyro data
                    reg_accel_az_h<=reg_accel_az_h(6 downto 0) & '0';
                elsif(unsigned(addr_reg)=accel_az_l_addr) then
                    MISO <= reg_accel_az_l(7);    --sending gyro data
                    reg_accel_az_l<=reg_accel_az_l(6 downto 0) & '0';
                else
                    MISO <= reg_error(7); --sending error signal from IMU simulator
                    reg_error<=reg_error(6 downto 0) & '0';
                    --report "read response wrong addres " severity error;
                end if;
            end if;
        elsif (count > 15) then
            --reporting
            report "Starting one SPI cycle report: " severity note;
            if (addr_reg(7)='1') then
                report "IMU read mode... " severity note;
                if(unsigned(addr_reg)=addr_80) then
                    report "    reading from addr 00.... read value: " & 
                    --to_string(to_integer(unsigned(dout))) & 
                    "dec" severity note;
                else
                    report "wrong reading adderss or unexpected data" severity ERROR;
                end if;
            elsif(addr_reg(7)='0') then
                report "IMU write mode... " severity note;
                if (unsigned(din_reg)=data_00) then
                    report "    writing zeros to addr: " & to_string(to_integer(unsigned(addr_reg))) & "dec" severity note;
                else
                    report "written wrong power init values" severity ERROR;
                end if;
            end if;
            --zeroing
            count <= (others=>'0');
            addr_reg <= (others=>'0');
            din_reg <= (others=>'0');
            reg_06 <= "11101010";
            reg_error <= (others=>'1');
            --IMU data simulation registers restoring default (after shifting)
            reg_gyro_ax_h <= x"2F";
            reg_gyro_ax_l <= x"4B";
            reg_gyro_ay_h <= x"68";
            reg_gyro_ay_l <= x"82";
            reg_gyro_az_h <= x"A3";
            reg_gyro_az_l <= x"C9";
            reg_accel_ax_h <= x"EF";
            reg_accel_ax_l <= x"04";
            reg_accel_ay_h <= x"2D";
            reg_accel_ay_l <= x"47";
            reg_accel_az_h <= x"61";
            reg_accel_az_l <= x"82";
            end if;


    end process simulation;

end Behavioral;
