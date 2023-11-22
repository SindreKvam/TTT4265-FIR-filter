library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx lfsr
-- https://docs.xilinx.com/v/u/en-US/xapp052

entity sine is
    port (
        clk : in std_logic;
        rst_n : in std_logic;

        ready : in std_logic;
        valid : out std_logic;
        data : out std_logic_vector(23 downto 0) := (others => '0')
    );
end sine;

architecture rtl of sine is

    type T_LOOKUP is array(0 to 31) of std_logic_vector(23 downto 0); 
    signal delay_line : T_LOOKUP := (others => (others => '0'));

    type T_STATE is (CALCULATE, HOLD_DATA_OUT);
    signal state : T_STATE := CALCULATE;
    signal phase : unsigned(4 downto 0) := (others => '0');

    constant coeff : T_LOOKUP :=  (
        x"800000", x"99c426", x"b27a40", x"c91f50", x"dcc602", x"eca05f", x"f80842", x"fe8620",
        x"ffd5f0", x"fbe9f2", x"f2eb41", x"e53823", x"d3602c", x"be1e5f", x"a65187", x"8cf315",
        x"730cea", x"59ae78", x"41e1a0", x"2c9fd3", x"1ac7dc", x"0d14be", x"04160d", x"002a0f",
        x"0179df", x"07f7bd", x"135fa0", x"2339fd", x"36e0af", x"4d85bf", x"663bd9", x"800000");
begin


    SINE_PROC : process(clk)

        variable v_valid : std_logic;

    begin
        if rising_edge(clk) then

            v_valid := '0';

            if rst_n = '0' then

                data  <= (others => '0');
                state <= CALCULATE;

            else

                case state is

                    -------------------------------
                    when CALCULATE =>
                        -------------------------------

                        state <= HOLD_DATA_OUT;
                        data  <= coeff(to_integer(phase));
                    -------------------------------
                    when HOLD_DATA_OUT =>
                        -------------------------------

                        v_valid  := '1';

                        if ready = '1' then
                            phase <= phase + 1;
                            state <= CALCULATE;
                        end if;
                
                    when others =>
                
                end case;

            end if;
            
            valid <= v_valid;
        end if;
        
    end process;

end architecture;