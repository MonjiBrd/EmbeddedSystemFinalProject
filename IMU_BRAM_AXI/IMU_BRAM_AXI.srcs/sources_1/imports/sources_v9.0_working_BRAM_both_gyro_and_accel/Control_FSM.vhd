----------------------------------------------------------------------------------
-- Company: SDU
-- Engineer: Arkadiusz Nowakowski
-- 
-- Create Date: 11/04/2021 04:04:49 PM
-- Design Name: SPI comunication
-- Module Name: Control_FSM - FSM
-- Project Name: IMU interface
-- Target Devices: Sparkfun ICM-20948
-- Tool Versions: 
-- Description: FMS for data-flow control - right IMU initialization, check and data sending controll through UART
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.std_logic_arith.all;
use IEEE.NUMERIC_STD.ALL;


entity Control_FSM is
    Port ( clk : in STD_LOGIC;
         rst : in STD_LOGIC;
         en : in STD_LOGIC;
         cs : in STD_LOGIC;
         din : in STD_LOGIC_VECTOR (7 downto 0);
         addr : out STD_LOGIC_VECTOR (7 downto 0);
         dout_TW : out STD_LOGIC_VECTOR (7 downto 0);
         addr_BRAM : out STD_LOGIC_VECTOR (31 downto 0);
         dout_BRAM : out STD_LOGIC_VECTOR (31 downto 0);
         wea_BRAM : out STD_LOGIC_VECTOR (3 downto 0);
         wr : out STD_LOGIC;
         LED_s : out STD_LOGIC;
         LED_e : out STD_LOGIC);
end Control_FSM;

architecture FSM of Control_FSM is

    signal scc_val : unsigned (7 downto 0):="11101010"; --read value indicating initialization success (0xEA from addr 0x00) - who am I
    signal mode_count : unsigned (4 downto 0); --counter to control which address to set up and if to send any data in write mode
    
    --IMU register addresses
        --gyroscope:
    signal gyro_ax_h_addr : std_logic_vector (7 downto 0) :=x"33"; --constant gyro axis x high byte register address
    signal gyro_ax_l_addr : std_logic_vector (7 downto 0) :=x"34";
    signal gyro_ay_h_addr : std_logic_vector (7 downto 0) :=x"35";
    signal gyro_ay_l_addr : std_logic_vector (7 downto 0) :=x"36";
    signal gyro_az_h_addr : std_logic_vector (7 downto 0) :=x"37";
    signal gyro_az_l_addr : std_logic_vector (7 downto 0) :=x"38";
        --accelerometer
    signal accel_ax_h_addr : std_logic_vector (7 downto 0) :=x"2D"; --constant accelerometer axis x low byte register address
    signal accel_ax_l_addr : std_logic_vector (7 downto 0) :=x"2E";
    signal accel_ay_h_addr : std_logic_vector (7 downto 0) :=x"2F";
    signal accel_ay_l_addr : std_logic_vector (7 downto 0) :=x"30";
    signal accel_az_h_addr : std_logic_vector (7 downto 0) :=x"31";
    signal accel_az_l_addr : std_logic_vector (7 downto 0) :=x"32";
        --magnetometer -- added by Monji 
    signal mag_ax_h_addr : std_logic_vector (7 downto 0) :=x"11"; --constant magnetometer axis x low byte register address
    signal mag_ax_l_addr : std_logic_vector (7 downto 0) :=x"12";
    signal mag_ay_h_addr : std_logic_vector (7 downto 0) :=x"13";
    signal mag_ay_l_addr : std_logic_vector (7 downto 0) :=x"14";
    signal mag_az_h_addr : std_logic_vector (7 downto 0) :=x"15";
    signal mag_az_l_addr : std_logic_vector (7 downto 0) :=x"16";

    --signal debug_addr : std_logic_vector (7 downto 0) :=x"00";  --addres for debbuging purposes2E";
    
    TYPE STATE_TYPE IS (
        s0,
        mode_init,
        mode_control,
        power_init,
        
        --monji
        mag_init,
        
        who_am_I,
        answer_check,
        success,
        error,
        gyro_ax_h,
        gyro_ax_l,
        gyro_ay_h,
        gyro_ay_l,
        gyro_az_h,
        gyro_az_l,
        accel_ax_h,
        accel_ax_l,
        accel_ay_h,
        accel_ay_l,
        accel_az_h,
        accel_az_l,
        
        -- added by Monji 
        mag_ax_h,
        mag_ax_l,
        mag_ay_h,
        mag_ay_l,
        mag_az_h,
        mag_az_l,
        -- end Monji
        
        wait_for_data,
        write_to_BRAM
    );

    -- State vector declaration
    ATTRIBUTE state_vector : string;
    ATTRIBUTE state_vector OF fsm : ARCHITECTURE IS "current_state" ;


    -- Declare current and next state signals
    SIGNAL current_state : STATE_TYPE ;
    SIGNAL next_state : STATE_TYPE ;

begin

    ----------------------------------------------------------------------------
    clocked : PROCESS(clk, rst)
        ----------------------------------------------------------------------------
    BEGIN
        IF (rst = '1') THEN
            current_state <= s0;
            -- Reset Values
            addr <= (others => '0');
            dout_TW <= (others => '0');
            mode_count <= (others => '0');
            wr <= '0';
            LED_e <= '0';
            LED_s <= '0';
            addr_BRAM <= (others=>'0');
            dout_BRAM <= (others=>'0');
            wea_BRAM <= (others=>'0');

        ELSIF (clk'EVENT AND clk = '1') THEN
            --FSM clocked by cs rising edge to perform address and data controll
            current_state <= next_state;
            -- Default Assignment To Internals

            -- Combined Actions for rising edge events
            CASE current_state IS
                WHEN s0 =>
                    wr <= '0';
                    LED_s <= '0';
                    addr <= (others => '0');
                    dout_TW <= (others => '0');
                    mode_count <= (others => '0');
                WHEN mode_control =>
                    NULL;
                WHEN mode_init =>
                    mode_count<=mode_count+1;
                    wea_BRAM<=(others=>'0');
                WHEN power_init =>
                    wr <= '1';
                    addr <= "00000110"; -- hex 06 with addr(7)='0' to write
                    dout_TW <= (others => '0'); -- zeros to PWR_MGMT_1 register to wake IMU up
                
                -- monji
                WHEN mag_init =>
                    wr <= '1';
                    addr <= x"31"; -- hex 31 with addr(7)='0' to write
                    dout_TW <= "00000010"; -- zeros to CNTL2 register to wake MAG up
                
                
                WHEN who_am_I =>
                    wr <= '0';
                    addr <= "10000000"; -- hex 00 with addr(7)='1' to read

                WHEN answer_check =>
                    NULL;
                WHEN success =>
                    LED_e <= '0';
                    LED_s <= '1';
                   -- mode_count <= x"1"; --only for debuding - mode will stay at who am I
                WHEN error =>
                    LED_e <= '1';
                    mode_count <= (others=>'0');
                WHEN gyro_ax_h =>
                    addr <= '1' & gyro_ax_h_addr(6 downto 0); --turning read mode on
                    wr <= '0';
                    addr_BRAM <= x"40000000";
                WHEN gyro_ax_l =>
                    addr <= '1' & gyro_ax_l_addr(6 downto 0);
                    wr <= '0';
                    addr_BRAM <= x"40000004";
                WHEN gyro_ay_h =>
                    addr <= '1' & gyro_ay_h_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000008";
                WHEN gyro_ay_l =>
                    addr <= '1' & gyro_ay_l_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"4000000C";
                WHEN gyro_az_h =>
                    addr <= '1' & gyro_az_h_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000010";
                WHEN gyro_az_l =>
                    addr <= '1' & gyro_az_l_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000014";
                WHEN accel_ax_h =>
                    addr <= '1' & accel_ax_h_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000018";
                WHEN accel_ax_l =>
                    addr <= '1' & accel_ax_l_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"4000001C";
                WHEN accel_ay_h =>
                    addr <= '1' & accel_ay_h_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000020";
                WHEN accel_ay_l =>
                    addr <= '1' & accel_ay_l_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000024";
                WHEN accel_az_h =>
                    addr <= '1' & accel_az_h_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000028";
                WHEN accel_az_l =>
                    addr <= '1' & accel_az_l_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"4000002C";
                    
                -- added by Monji  
                WHEN mag_ax_h =>
                    addr <= '1' & mag_ax_h_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000030";
                WHEN mag_ax_l =>
                    addr <= '1' & mag_ax_l_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000034";
                WHEN mag_ay_h =>
                    addr <= '1' & mag_ay_h_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000038";
                WHEN mag_ay_l =>
                    addr <= '1' & mag_ay_l_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"4000003C";
                WHEN mag_az_h =>
                    addr <= '1' & mag_az_h_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000040";
                WHEN mag_az_l =>
                    addr <= '1' & mag_az_l_addr(6 downto 0); 
                    wr <= '0';
                    addr_BRAM <= x"40000044";    
                    -- end Monji
                    
                    mode_count <= "00011"; --keep this on the last register read to loop after initialization
                WHEN wait_for_data =>
                    NULL;
                WHEN write_to_BRAM => 
                    dout_BRAM (7 downto 0) <= din;
                    wea_BRAM <= (others=>'1');
                WHEN OTHERS =>
                    NULL;
            END CASE;
        END IF;

    END PROCESS clocked;

    ----------------------------------------------------------------------------
    nextstate : PROCESS (en, din, cs, mode_count, current_state)
        ----------------------------------------------------------------------------
    BEGIN
        CASE current_state IS
            WHEN s0 =>
                IF (en = '1') THEN
                    next_state <= mode_init;
                ELSE
                    next_state <= s0;
                END IF;
                
            WHEN mode_init =>
                next_state <= mode_control;
                
            WHEN mode_control =>
                IF (cs = '1' and mode_count=1) THEN
                    next_state <= power_init;            
                ELSIF (cs='1' and mode_count=2) THEN
                    next_state <= who_am_I;    
                
                    
                   -- monji                             
                ELSIF (cs='1' and mode_count=3) THEN 
                    next_state <= mag_init;  
                
                
                ELSIF (cs='1' and mode_count=4) THEN
                    next_state <= gyro_ax_h;
                ELSIF (cs='1' and mode_count=5) THEN
                    next_state <= gyro_ax_l;
                ELSIF (cs='1' and mode_count=6) THEN
                    next_state <= gyro_ay_h;
                ELSIF (cs='1' and mode_count=7) THEN
                    next_state <= gyro_ay_l;
                ELSIF (cs='1' and mode_count=8) THEN
                    next_state <= gyro_az_h;
                ELSIF (cs='1' and mode_count=9) THEN
                    next_state <= gyro_az_l;
                ELSIF (cs='1' and mode_count=10) THEN
                    next_state <= accel_ax_h;
                ELSIF (cs='1' and mode_count=11) THEN
                    next_state <= accel_ax_l;
                ELSIF (cs='1' and mode_count=12) THEN
                    next_state <= accel_ay_h;
                ELSIF (cs='1' and mode_count=13) THEN
                    next_state <= accel_ay_l;
                ELSIF (cs='1' and mode_count=14) THEN
                    next_state <= accel_az_h;
                ELSIF (cs='1' and mode_count=15) THEN
                    next_state <= accel_az_l;
                    
                    -- added by Monji 
                ELSIF (cs='1' and mode_count=16) THEN
                    next_state <= mag_ax_h;
                ELSIF (cs='1' and mode_count=17) THEN
                    next_state <= mag_ax_l;
                ELSIF (cs='1' and mode_count=18) THEN
                    next_state <= mag_ay_h;
                ELSIF (cs='1' and mode_count=19) THEN
                    next_state <= mag_ay_l;
                ELSIF (cs='1' and mode_count=20) THEN
                    next_state <= mag_az_h;
                ELSIF (cs='1' and mode_count=21) THEN
                    next_state <= mag_az_l;
                    -- end Monji 
                    
                ELSE
                    next_state <= mode_control;
                END IF;
                
                
            WHEN power_init =>
                IF (cs='0') THEN
                    next_state <= mode_init;
                ELSE
                    next_state<= power_init;
                END IF;
                
                
            WHEN who_am_I =>
                IF (cs='0') THEN
                    next_state<= answer_check;
                ELSE
                    next_state<= who_am_I;
                END IF;
            
                            
            -- monji    
            WHEN mag_init =>
                IF (cs='0') THEN
                    next_state<= mode_init;
                ELSE
                    next_state<= mag_init;
                END IF;
            -- end monji
            
            WHEN answer_check =>
                IF (cs='1' and unsigned(din) = scc_val) THEN
                    next_state <= success;
                ELSIF (cs='1') THEN
                    next_state <= error;
                ELSE
                    next_state<=answer_check;
                END IF;
                
            WHEN success =>
                IF (cs='0') THEN
                    next_state<= mode_init;
                ELSE
                    next_state<= success;
                END IF;
            WHEN error =>
                next_state <= s0;
                
            WHEN gyro_ax_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= gyro_ax_h;
                END IF;
            WHEN gyro_ax_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= gyro_ax_l;
                END IF;
            WHEN gyro_ay_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= gyro_ay_h;
                END IF;
            WHEN gyro_ay_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= gyro_ay_l;
                END IF;
            WHEN gyro_az_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= gyro_az_h;
                END IF;
            WHEN gyro_az_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= gyro_az_l;
                END IF;
            WHEN accel_ax_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= accel_ax_h;
                END IF;
            WHEN accel_ax_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= accel_ax_l;
                END IF;
            WHEN accel_ay_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= accel_ay_h;
                END IF;
            WHEN accel_ay_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= accel_ay_l;
                END IF;
            WHEN accel_az_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= accel_az_h;
                END IF;
            WHEN accel_az_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= accel_az_l;
                END IF;
                
                
                -- added by Monji    
                
            WHEN mag_ax_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= mag_ax_h;
                END IF;
            WHEN mag_ax_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= mag_ax_l;
                END IF;
            WHEN mag_ay_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= mag_ay_h;
                END IF;
            WHEN mag_ay_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= mag_ay_l;
                END IF;
            WHEN mag_az_h =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= mag_az_h;
                END IF;
            WHEN mag_az_l =>
                IF (cs='0') THEN
                    next_state <= wait_for_data;
                ELSE
                    next_state <= mag_az_l;
                END IF;
                
                -- end Monji    
                
                
            WHEN wait_for_data => 
                IF (cs='1') THEN
                    next_state <= write_to_BRAM;
                ELSE
                    next_state <= wait_for_data;
                END IF;
            WHEN write_to_BRAM => 
                next_state <= mode_init;
            WHEN OTHERS =>
                next_state <= s0;
        END CASE;

    END PROCESS nextstate;


end FSM;
