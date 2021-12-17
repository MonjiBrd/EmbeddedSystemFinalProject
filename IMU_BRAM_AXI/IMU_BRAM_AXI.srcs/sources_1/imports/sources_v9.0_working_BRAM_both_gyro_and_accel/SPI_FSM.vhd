----------------------------------------------------------------------------------
-- Company: SDU
-- Engineer: Arkadiusz Nowakowski
-- 
-- Create Date: 11/03/2021 06:21:09 PM
-- Design Name: SPI comunication
-- Module Name: SPI_FSM - rtl
-- Project Name: IMU interface
-- Target Devices: Sparkfun ICM-20948
-- Tool Versions: 
-- Description: FMS for IMU interface through SPI
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
--USE ieee.std_logic_arith.all;
use IEEE.NUMERIC_STD.ALL;

entity SPI_FSM is
    Port ( clk : in STD_LOGIC;
         rst : in STD_LOGIC;
         en : in STD_LOGIC;
         addr : in STD_LOGIC_VECTOR (7 downto 0);
         din : in std_logic_vector (7 downto 0);
         wr : in std_logic;
         MISO : in STD_LOGIC;
         SCLK : out STD_LOGIC;
         MOSI : out STD_LOGIC;
         cs : out STD_LOGIC;
         dout : out STD_LOGIC_VECTOR (7 downto 0));
end SPI_FSM;

architecture fsm of SPI_FSM is

    signal addr_reg : std_logic_vector (7 downto 0);
    signal din_reg : std_logic_vector (7 downto 0);
    signal dout_reg : std_logic_vector (7 downto 0);
    signal count : UNSIGNED (3 downto 0);

    TYPE STATE_TYPE IS (
        s0,
        init,
        load,
        addr_transition,
        addr_shift,
        cntr_rst1,
        delayState,
        cntr_rst2,
        writing_data_transition,
        writing_data_shift,
        writing_done,
        reading_data_init,
        reading_data_latch,
        reading_done,
        delay2State
    );

    -- State vector declaration
    ATTRIBUTE state_vector : string;
    ATTRIBUTE state_vector OF fsm : ARCHITECTURE IS "current_state" ;


    -- Declare current and next state signals
    SIGNAL current_state : STATE_TYPE ;
    SIGNAL next_state : STATE_TYPE ;

begin

    ----------------------------------------------------------------------------
    clocked : PROCESS(
clk,
 rst
)
        ----------------------------------------------------------------------------
    BEGIN
        IF (rst = '1') THEN
            current_state <= s0;
            -- Reset Values
            count <= (others=>'0');
            addr_reg <= (others=>'0');
            din_reg <= (others=>'0');
            dout_reg <= (others=>'0');

        ELSIF (clk'EVENT AND clk = '1') THEN
            current_state <= next_state;
            -- Default Assignment To Internals

            -- Combined Actions for rising edge events
            CASE current_state IS
                WHEN s0 =>
                    MOSI <= '1';
                    cs <= '1';
                    SCLK <= '1';
                    count <= (others=>'0');
                WHEN init =>
                    cs <= '0';
                WHEN load =>
                    addr_reg <= addr;
                    din_reg <= din;
                WHEN addr_transition =>
                    SCLK <= '0';
                    MOSI <= addr_reg(7);
                WHEN addr_shift =>
                    SCLK <= '1';
                    addr_reg<=addr_reg(6 downto 0) & '0';
                    count<=count+1;
                WHEN cntr_rst1 =>
                    count <= (others=>'0');
                    MOSI <= '1';
                WHEN delayState =>
                    SCLK <= '1';
                    count <= count + 1;
                WHEN cntr_rst2 =>
                    count <= (others=>'0');
                WHEN writing_data_transition =>
                    SCLK <= '0';
                    MOSI <= din_reg(7);
                WHEN writing_data_shift =>
                    SCLK <= '1';
                    din_reg<=din_reg(6 downto 0) & '0';
                    count<=count+1;
                WHEN writing_done =>
                    SCLK <= '1';
                    MOSI <= '1';
                    count <= (others=>'0');
                WHEN reading_data_init =>
                    SCLK <= '0';
                WHEN reading_data_latch =>
                    SCLK <= '1';
                    dout_reg <= dout_reg(6 downto 0) & MISO;
                    count<=count+1;
                WHEN reading_done =>
                    SCLK <= '1';
                    dout<=dout_reg;
                    count <= (others=>'0');
                WHEN delay2State =>
                    cs<='1';
                    count<=count+1;
                WHEN OTHERS =>
                    NULL;
            END CASE;
        END IF;

    END PROCESS clocked;

    ----------------------------------------------------------------------------
    nextstate : PROCESS (
en,
 wr,
 count,
 current_state
)
        ----------------------------------------------------------------------------
    BEGIN
        CASE current_state IS
            WHEN s0 =>
                IF (en = '1') THEN
                    next_state <= init;
                ELSE
                    next_state <= s0;
                END IF;
            WHEN init =>
                next_state <= load;
            WHEN load =>
                next_state <= addr_transition;
            WHEN addr_transition =>
                next_state <= addr_shift;
            WHEN addr_shift =>
                IF (count = 7) THEN
                    next_state <= cntr_rst1;
                ELSE
                    next_state <= addr_transition;
                END IF;
            WHEN cntr_rst1 =>
                next_state <= delayState;
            WHEN delayState =>
                IF (count = 7) THEN
                    next_state <= cntr_rst2;
                ELSE
                    next_state <= delayState;
                END IF;
            WHEN cntr_rst2 =>
                IF (wr = '1') THEN
                    next_state <= writing_data_transition;
                ELSIF (wr = '0') THEN
                    next_state <= reading_data_init;
                ELSE
                    next_state <= cntr_rst2;
                END IF;
            WHEN writing_data_transition =>
                next_state<=writing_data_shift;
            WHEN writing_data_shift =>
                IF (count = 7) THEN
                    next_state <= writing_done;
                ELSE
                    next_state <= writing_data_transition;
                END IF;
            WHEN writing_done =>
                next_state <= delay2State;
            WHEN reading_data_init =>
                next_state <= reading_data_latch;
            WHEN reading_data_latch =>
                IF (count = 7) THEN
                    next_state <= reading_done;
                ELSE
                    next_state <= reading_data_init;
                END IF;
            WHEN reading_done =>
                next_state <= delay2State;
            WHEN delay2State =>
                IF (count = 7) THEN
                    next_state <= s0;
                ELSE
                    next_state <= delay2State;
                END IF;
            WHEN OTHERS =>
                next_state <= s0;
        END CASE;

    END PROCESS nextstate;

end fsm;
