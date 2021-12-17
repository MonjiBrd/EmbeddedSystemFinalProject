----------------------------------------------------------------------------------
-- Company: SDU
-- Engineer: Arkadiusz Nowakowski
-- 
-- Create Date: 11/06/2021 01:56:51 PM
-- Design Name: SPI comunication
-- Module Name: Control_FSM_tb - Behavioral
-- Project Name: IMU interface
-- Target Devices: Sparkfun ICM-20948
-- Tool Versions: 
-- Description: Testbench for FMS for data-flow control
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Control_FSM_tb is
    --  Port ( );
end Control_FSM_tb;

architecture Behavioral of Control_FSM_tb is
    --inputs
    signal clk : STD_LOGIC;
    signal rst :  STD_LOGIC;
    signal en :  STD_LOGIC;
    signal cs :  STD_LOGIC;
    signal din :  STD_LOGIC_VECTOR (7 downto 0);
    --outputs
    signal addr :  STD_LOGIC_VECTOR (7 downto 0);
    signal dout_TW :  STD_LOGIC_VECTOR (7 downto 0);
    signal addr_BRAM : STD_LOGIC_VECTOR (31 downto 0);
    signal dout_BRAM : STD_LOGIC_VECTOR (31 downto 0);
    signal wea_BRAM : STD_LOGIC_VECTOR (3 downto 0);
    signal wr :  STD_LOGIC;
    signal LED_s :  STD_LOGIC;
    signal LED_e :  STD_LOGIC;

    constant T : time := 8ns; --125MHz clock period
    constant cs_low : time := 750ns; --duration of spi cycle in SPI_FSM (for 125MHz clock)
    constant cs_high : time := 250ns; --duration of waiting inbetween SPI cycles in SPI_FSM (for 125MHz clock)

    signal test_count : integer range 0 to 4 := 0;


    -- State vector declaration
    ATTRIBUTE state_vector : string;
    ATTRIBUTE state_vector OF Behavioral : ARCHITECTURE IS "current_state" ;

    --problem to solve: I can enter external signall but how to enter external localy-defined type.   
    --alias machine_current_state is << signal .Control_FSM_tb.design_top_unit.current_state : state_type>>;
    --alias machine_mode_counter is << signal .Control_FSM_tb.design_top_unit.mode_count : unsigned (3 downto 0)>>;
    --in case of syntax error change language type to VHDL 2008 in Source File Properties (to use external names)

begin

    design_top_unit : entity work.Control_FSM
        port map (clk=>clk,rst=>rst,en=>en,cs=>cs,din=>din,addr=>addr,dout_TW=>dout_TW,wr=>wr,LED_s=>LED_s,
                 LED_e=>LED_e, addr_BRAM=>addr_BRAM, dout_BRAM=>dout_BRAM, wea_BRAM=>wea_BRAM );

    clock : process
    begin
        clk<='0';
        wait for T;
        clk<='1';
        wait for T;
    end process clock;

    --from SPI_FMS tests we know that in SPI full cycle has period circa 1000ns (with clock T=8ns)
    cs_clock : process
    begin
        cs<='1';
        wait for cs_high;
        cs<='0';
        wait for cs_low;
    end process cs_clock;

    rst<='1','0' after 2*T;
    en<='0','1' after 2*T;

    simulation : process(
cs
)
    begin
        if(cs'event and cs='1') then
            case test_count is
                when 0 =>
                    din <= x"00";
                when 1=>
                    din <= x"FF";
                when 2=>
                    din <= x"01";
                when 3=>
                    din <= x"07";    
                when 4=>
                    din <= x"EA";
                when others =>
                    din <= x"00";
            end case;
            test_count<=test_count+1;
            if (test_count > 4) then
                test_count<=0;
            end if;
        end if;

    end process simulation;

    assert LED_s='1' report "reached succes state." severity NOTE;
    assert LED_e='1' report "Initialization failed." severity ERROR;

end Behavioral;
